#!/usr/bin/env bash
# Pin the artwork and its metadata to IPFS, then record both CIDs in the repo.
#
#   ./image/pin.sh upload                    pin both files via Pinata (needs $PINATA_JWT)
#   ./image/pin.sh set-image <CID>           point metadata.json at an already-pinned image
#   ./image/pin.sh record <IMG_CID> <META_CID>   write both CIDs into the repo
#   ./image/pin.sh check                     verify the recorded CIDs resolve
#
# The manual subcommands exist so the web UI of any pinning service works just as
# well as the API: upload by hand, then hand the CIDs to set-image / record.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="$ROOT/image/42berry-cross-coalition.jpg"
META="$ROOT/image/metadata.json"
RECORD="$ROOT/deployment/ipfs.json"
DEPLOY_README="$ROOT/deployment/README.md"
GATEWAY="https://ipfs.io/ipfs"

die() { echo "error: $*" >&2; exit 1; }

# Upload one file to Pinata. Tries the current v3 files API first and falls back to
# the legacy pinning endpoint, since which one an account can reach depends on when
# it was created. Prints the bare CID on stdout; everything else goes to stderr.
pin_file() {
    local path="$1" response cid
    [ -f "$path" ] || die "no such file: $path"
    [ -n "${PINATA_JWT:-}" ] || die "PINATA_JWT is not set (Pinata dashboard -> API Keys)"

    echo "uploading $(basename "$path") ($(stat -c %s "$path") bytes)..." >&2

    response=$(curl -sS -X POST "https://uploads.pinata.cloud/v3/files" \
        -H "Authorization: Bearer $PINATA_JWT" \
        -F "network=public" -F "file=@$path" 2>/dev/null || true)
    cid=$(printf '%s' "$response" | jq -r '.data.cid // empty' 2>/dev/null || true)

    if [ -z "$cid" ]; then
        response=$(curl -sS -X POST "https://api.pinata.cloud/pinning/pinFileToIPFS" \
            -H "Authorization: Bearer $PINATA_JWT" \
            -F "file=@$path")
        cid=$(printf '%s' "$response" | jq -r '.IpfsHash // empty')
    fi

    [ -n "$cid" ] || die "upload failed, service replied: $response"
    echo "$cid"
}

# Rewrite only the image line, so the hand-aligned formatting of metadata.json survives.
set_image() {
    local cid="$1"
    [ -n "$cid" ] || die "set-image needs a CID"
    grep -q '"image": "ipfs://' "$META" || die "no image field found in $META"
    sed -i 's|"image": "ipfs://[^"]*"|"image": "ipfs://'"$cid"'"|' "$META"
    jq empty "$META" || die "metadata.json is no longer valid JSON"
    echo "metadata.json -> ipfs://$cid"
}

record() {
    local img="$1" meta="$2"
    [ -n "$img" ] && [ -n "$meta" ] || die "record needs <image CID> <metadata CID>"

    jq -n --arg img "$img" --arg meta "$meta" \
          --arg sha "$(sha256sum "$IMAGE" | cut -d' ' -f1)" \
          --arg date "$(date -u +%Y-%m-%d)" '{
        image:    { cid: $img,  file: "image/42berry-cross-coalition.jpg", sha256: $sha },
        metadata: { cid: $meta, file: "image/metadata.json" },
        tokenURI: ("ipfs://" + $meta),
        pinned_on: $date
    }' > "$RECORD"

    # Fill the placeholders in the deployment guide, so the table and ipfs.json agree.
    sed -i "s|<IMAGE_CID>|$img|g; s|<METADATA_CID>|$meta|g" "$DEPLOY_README"

    echo "recorded in deployment/ipfs.json and deployment/README.md"
    echo "mint with: ipfs://$meta"
}

check() {
    [ -f "$RECORD" ] || die "nothing recorded yet, run: $0 record <image CID> <metadata CID>"
    local img meta code
    img=$(jq -r .image.cid "$RECORD")
    meta=$(jq -r .metadata.cid "$RECORD")

    for cid in "$img" "$meta"; do
        code=$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 120 "$GATEWAY/$cid")
        echo "$GATEWAY/$cid -> HTTP $code"
        # A public gateway needs a while to find a freshly pinned block; a non-200 here
        # is worth retrying once before concluding the pin is bad.
        [ "$code" = "200" ] || die "$cid did not resolve (HTTP $code)"
    done

    # The whole point of the two-file layout: the pinned JSON must point at the pinned image.
    local remote
    remote=$(curl -sSL --max-time 120 "$GATEWAY/$meta" | jq -r '.image // "unreadable"')
    if [ "$remote" = "ipfs://$img" ]; then
        echo "pinned metadata points at the pinned image"
    else
        die "pinned metadata says image=$remote, expected ipfs://$img"
    fi
}

case "${1:-}" in
    upload)
        img_cid=$(pin_file "$IMAGE")
        echo "image CID: $img_cid"
        set_image "$img_cid"
        meta_cid=$(pin_file "$META")   # must happen after set_image: the CID covers the edit
        echo "metadata CID: $meta_cid"
        record "$img_cid" "$meta_cid"
        ;;
    set-image) set_image "${2:-}" ;;
    record)    record "${2:-}" "${3:-}" ;;
    check)     check ;;
    *) sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 1 ;;
esac
