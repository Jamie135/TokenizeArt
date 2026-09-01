#!/usr/bin/env bash
# Pin the artwork and its metadata to IPFS, then record both CIDs in the repo.
#
#   ./image/pin.sh upload                    pin both files via Pinata (needs $PINATA_JWT)
#   ./image/pin.sh set-image <CID>           point metadata.json at an already-pinned image
#   ./image/pin.sh record <IMG_CID> <META_CID>   write both CIDs into the repo
#   ./image/pin.sh check                     verify the recorded CIDs resolve
#   ./image/pin.sh status                    ask Pinata whether it holds them
#
# The manual subcommands exist so the web UI of any pinning service works just as
# well as the API: upload by hand, then hand the CIDs to set-image / record.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="$ROOT/image/42berry-cross-coalition.jpg"
META="$ROOT/image/metadata.json"
RECORD="$ROOT/deployment/ipfs.json"
DEPLOY_README="$ROOT/deployment/README.md"
# Public gateways routinely 504 on freshly pinned content: the block exists, but the
# gateway has not yet learned who provides it. So retrieval is tried across several
# gateways over a few rounds, and any one of them succeeding is proof enough.
# PROVIDER_GATEWAY may name your pinning provider's own gateway (ipfs.filebase.io, a
# …mypinata.cloud domain). It is queried too, but never counts as proof of public
# reachability: it serves your pins from the provider's storage, not over IPFS.
GATEWAYS=("https://dweb.link/ipfs" "https://ipfs.io/ipfs" "https://w3s.link/ipfs")
DEDICATED_GW=""
if [ -n "${PROVIDER_GATEWAY:-}" ]; then
    DEDICATED_GW="https://${PROVIDER_GATEWAY#https://}/ipfs"
    GATEWAYS=("$DEDICATED_GW" "${GATEWAYS[@]}")
fi
ROUNDS="${PIN_CHECK_ROUNDS:-3}"

die() { echo "error: $*" >&2; exit 1; }

# Upload one file to Pinata. Tries the current v3 files API first and falls back to
# the legacy pinning endpoint, since which one an account can reach depends on when
# it was created. Prints the bare CID on stdout; everything else goes to stderr.
pin_file() {
    local path="$1" response cid
    [ -f "$path" ] || die "no such file: $path"
    [ -n "${PINATA_JWT:-}" ] || die "PINATA_JWT is not set (Pinata dashboard -> API Keys)"

    echo "uploading $(basename "$path") ($(stat -c %s "$path") bytes)..." >&2

    # PIN_API=legacy skips v3 entirely. Worth reaching for when v3 returns a CID that no
    # public gateway can resolve: the legacy endpoint only ever pins to the public network,
    # whereas a v3 upload that does not register as public is stored privately and is
    # never advertised to IPFS, so the CID looks valid but resolves nowhere.
    if [ "${PIN_API:-}" != "legacy" ]; then
        response=$(curl -sS -X POST "https://uploads.pinata.cloud/v3/files" \
            -H "Authorization: Bearer $PINATA_JWT" \
            -F "network=public" -F "file=@$path" 2>/dev/null || true)
        cid=$(printf '%s' "$response" | jq -r '.data.cid // empty' 2>/dev/null || true)

        # A v3 response that says the file is private is a CID we must not record.
        if [ -n "$cid" ] && [ "$(printf '%s' "$response" | jq -r '.data.network // "public"')" != "public" ]; then
            echo "warning: v3 stored this privately, retrying on the legacy public endpoint" >&2
            cid=""
        fi
    fi

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

    # The table is regenerated between markers rather than patched in place. Substituting
    # placeholders only works the first time, so re-pinning to another service used to
    # leave the old, dead CIDs sitting in the guide while ipfs.json told the truth.
    local section
    section=$(cat <<-TABLE
	| | CID | Gateway |
	|---|---|---|
	| Artwork (JPEG) | \`$img\` | [view](https://ipfs.io/ipfs/$img) |
	| Metadata (JSON) | \`$meta\` | [view](https://ipfs.io/ipfs/$meta) |

	Token URI passed to \`mint\`:

	\`\`\`
	ipfs://$meta
	\`\`\`
	TABLE
    )

    grep -q '<!-- ipfs:begin -->' "$DEPLOY_README" || die "markers missing in $DEPLOY_README"
    awk -v new="$section" '
        /<!-- ipfs:begin -->/ { print; print new; skip = 1; next }
        /<!-- ipfs:end -->/   { skip = 0 }
        !skip                 { print }
    ' "$DEPLOY_README" > "$DEPLOY_README.tmp" && mv "$DEPLOY_README.tmp" "$DEPLOY_README"

    echo "recorded in deployment/ipfs.json and deployment/README.md"
    echo "mint with: ipfs://$meta"
}

# Fetch a CID, and separately establish whether any *public* gateway can serve it.
# These are different questions: a provider's own gateway serves your pins straight
# from that provider's storage, so it answers 200 even for content that was never advertised to
# public IPFS. Stopping at the first success would hide exactly the failure that matters,
# so every gateway in a round is tried. Sets PUBLIC_HIT=yes if a non-dedicated one answers.
PUBLIC_HIT=no
fetch_cid() {
    local cid="$1" round gw code body saved=""
    for ((round = 1; round <= ROUNDS; round++)); do
        for gw in "${GATEWAYS[@]}"; do
            body=$(mktemp)
            code=$(curl -sSL -o "$body" -w '%{http_code}' --max-time 30 "$gw/$cid" 2>/dev/null || echo 000)
            echo "  $(echo "$gw" | cut -d/ -f3): HTTP $code" >&2
            if [ "$code" = "200" ]; then
                [ -z "$saved" ] && { saved=$(mktemp); cat "$body" > "$saved"; }
                [ "$gw" != "$DEDICATED_GW" ] && PUBLIC_HIT=yes
            fi
            rm -f "$body"
        done
        # Nothing more to learn once the content is in hand and publicly reachable.
        [ -n "$saved" ] && [ "$PUBLIC_HIT" = yes ] && break
        [ "$round" -lt "$ROUNDS" ] && { echo "  round $round incomplete, waiting 30s..." >&2; sleep 30; }
    done
    [ -n "$saved" ] || return 1
    cat "$saved"; rm -f "$saved"
}

check() {
    [ -f "$RECORD" ] || die "nothing recorded yet, run: $0 record <image CID> <metadata CID>"
    local img meta remote
    img=$(jq -r .image.cid "$RECORD")
    meta=$(jq -r .metadata.cid "$RECORD")

    echo "image $img"
    fetch_cid "$img" > /dev/null || die "image did not resolve anywhere; run '$0 status'"

    echo "metadata $meta"
    remote=$(fetch_cid "$meta") || die "metadata did not resolve anywhere; run '$0 status'"

    # The whole point of the two-file layout: the pinned JSON must point at the pinned image.
    remote=$(printf '%s' "$remote" | jq -r '.image // "unreadable"')
    [ "$remote" = "ipfs://$img" ] || die "pinned metadata says image=$remote, expected ipfs://$img"
    echo "pinned metadata points at the pinned image"

    if [ "$PUBLIC_HIT" = no ]; then
        echo
        echo "NOT SAFE TO MINT: only your provider's own gateway served this content."
        echo "No independent gateway could fetch it, so wallets, marketplaces and anyone"
        echo "without that gateway URL would see a broken token, permanently. The provider"
        echo "is announcing the CID without serving the blocks; re-uploading to the same"
        echo "provider will not fix it. Pin the files to a second service and re-record."
        return 1
    fi
    echo "OK - reachable from public IPFS"
}

# Ask Pinata directly whether it holds these CIDs. This separates "not pinned" from
# "pinned but not yet reachable through a public gateway", which look identical from outside.
status() {
    [ -f "$RECORD" ] || die "nothing recorded yet"
    [ -n "${PINATA_JWT:-}" ] || die "PINATA_JWT is not set"
    local cid
    for cid in $(jq -r '.image.cid, .metadata.cid' "$RECORD"); do
        echo "== $cid"
        curl -sS -H "Authorization: Bearer $PINATA_JWT" \
            "https://api.pinata.cloud/v3/files/public?cid=$cid" |
            jq -r '.data.files[]? | "  v3 public: \(.name)  \(.size) bytes  created \(.created_at)"' 2>/dev/null
        curl -sS -H "Authorization: Bearer $PINATA_JWT" \
            "https://api.pinata.cloud/v3/files/private?cid=$cid" |
            jq -r '.data.files[]? | "  v3 PRIVATE: \(.name)  \(.size) bytes - private files are not public on IPFS"' 2>/dev/null
        curl -sS -H "Authorization: Bearer $PINATA_JWT" \
            "https://api.pinata.cloud/data/pinList?status=pinned&hashContains=$cid" |
            jq -r '.rows[]? | "  legacy pinned: \(.metadata.name // "-")  \(.size) bytes  \(.date_pinned)"' 2>/dev/null
    done
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
    status)    status ;;
    *) sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 1 ;;
esac
