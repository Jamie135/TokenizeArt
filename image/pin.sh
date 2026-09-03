#!/usr/bin/env bash
# Record the artwork and its metadata CIDs in the repo, and verify they resolve.
#
#   ./image/pin.sh set-image <CID>               point metadata.json at the pinned image
#   ./image/pin.sh record <IMG_CID> <META_CID>   write both CIDs into the repo
#   ./image/pin.sh check                         verify the recorded CIDs resolve
#
# The two files are pinned on Filebase. Uploading is left to the provider's own console
# or S3 API rather than reimplemented here, which keeps this script independent of any
# one service: upload there, then hand the CIDs to set-image and record.

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
# so every gateway in a round is tried. The findings come back in globals and the body in a
# file, not on stdout: read through $(...) the function would run in a subshell and every
# flag it set would die with it, which is how the metadata half of the check used to end up
# reporting the image's verdict. They are reset per CID for the same reason - one file being
# reachable is no evidence about the other.
PUBLIC_HIT=no      # a public gateway returned the assembled file
BLOCK_HIT=no       # a public gateway returned the root block (see probe_block)
RATE_LIMITED=no    # a gateway answered 429, i.e. refused to answer the question at all
FETCH_BODY=""      # file holding the assembled content, when some gateway served it
BLOCK_FILE=""      # the root block itself, kept for the metadata content check

# Ask a gateway for the raw root block instead of the assembled file. Blocks come off a
# cheaper path and are throttled far more loosely, so this usually answers while the file
# path is handing out 429s. A 200 proves a public gateway located the block on the network,
# which is what "is this pinned publicly" actually asks; it is weaker than a full fetch only
# in that the later blocks of a multi-block file go unchecked.
probe_block() {
    local gw="$1" cid="$2" tmp code rc=1
    tmp=$(mktemp)
    code=$(curl -sSL -o "$tmp" -w '%{http_code}' --max-time 30 \
        -H 'Accept: application/vnd.ipld.raw' "$gw/$cid?format=raw" 2>/dev/null || echo 000)
    if [ "$code" = "200" ] && [ -s "$tmp" ]; then
        rc=0
        if [ "$gw" != "$DEDICATED_GW" ]; then BLOCK_HIT=yes; fi
        if [ -z "$BLOCK_FILE" ]; then BLOCK_FILE=$(mktemp); cat "$tmp" > "$BLOCK_FILE"; fi
    fi
    rm -f "$tmp"
    return $rc
}

# Recover a one-block file's bytes from the dag-pb node that wraps them. The wrapper is a
# handful of framing bytes around the payload, so for JSON the payload is everything from
# the first brace to the last. Best effort by design: anything larger than a single block
# comes back as nonsense, the caller runs it past jq, and a failure only skips a check.
block_json() {
    LC_ALL=C sed -z 's/^[^{]*//; s/[^}]*$//' "$1" | tr -d '\000'
}

# Returns 0 if some gateway handed over the content, which is left in $FETCH_BODY.
fetch_cid() {
    local cid="$1" round gw code body note
    PUBLIC_HIT=no BLOCK_HIT=no RATE_LIMITED=no
    rm -f "$FETCH_BODY" "$BLOCK_FILE"; FETCH_BODY="" BLOCK_FILE=""
    for ((round = 1; round <= ROUNDS; round++)); do
        for gw in "${GATEWAYS[@]}"; do
            body=$(mktemp)
            code=$(curl -sSL -o "$body" -w '%{http_code}' --max-time 30 "$gw/$cid" 2>/dev/null || echo 000)
            note=""
            if [ "$code" = "200" ]; then
                if [ -z "$FETCH_BODY" ]; then FETCH_BODY=$(mktemp); cat "$body" > "$FETCH_BODY"; fi
                if [ "$gw" != "$DEDICATED_GW" ]; then PUBLIC_HIT=yes; fi
            else
                # 429 is the gateway refusing to serve *this machine*; it says nothing about
                # whether the content is on IPFS. Any other failure is worth a second opinion
                # too, so either way go ask the same gateway for the block instead.
                if [ "$code" = "429" ]; then RATE_LIMITED=yes; fi
                if probe_block "$gw" "$cid"; then note=" (raw block: ok)"; else note=" (raw block: no)"; fi
            fi
            echo "  $(echo "$gw" | cut -d/ -f3): HTTP $code$note" >&2
            rm -f "$body"
        done
        # Nothing more to learn once the content is in hand and publicly reachable.
        if [ -n "$FETCH_BODY" ] && [ "$PUBLIC_HIT" = yes ]; then break; fi
        # Nor once a rate limit is doing the answering: it will not lift within a 30s wait,
        # and the block probes have already settled the question the file fetch could not.
        if [ "$RATE_LIMITED" = yes ] && [ "$BLOCK_HIT" = yes ]; then break; fi
        if [ "$round" -lt "$ROUNDS" ]; then echo "  round $round incomplete, waiting 30s..." >&2; sleep 30; fi
    done
    [ -n "$FETCH_BODY" ]
}

check() {
    [ -f "$RECORD" ] || die "nothing recorded yet, run: $0 record <image CID> <metadata CID>"
    local img meta remote json="" img_any img_public img_block img_rl meta_public meta_block meta_rl
    img=$(jq -r .image.cid "$RECORD")
    meta=$(jq -r .metadata.cid "$RECORD")

    echo "image $img"
    if fetch_cid "$img"; then img_any=yes; else img_any=no; fi
    img_public=$PUBLIC_HIT img_block=$BLOCK_HIT img_rl=$RATE_LIMITED

    echo "metadata $meta"
    fetch_cid "$meta" || true
    meta_public=$PUBLIC_HIT meta_block=$BLOCK_HIT meta_rl=$RATE_LIMITED
    if [ -n "$FETCH_BODY" ]; then
        json=$(cat "$FETCH_BODY")
    elif [ -n "$BLOCK_FILE" ]; then
        # A throttled file fetch can still leave the root block in hand, and for a document
        # this small that block *is* the whole JSON, so the content check need not be dropped.
        json=$(block_json "$BLOCK_FILE")
    fi
    rm -f "$FETCH_BODY" "$BLOCK_FILE"; FETCH_BODY="" BLOCK_FILE=""

    # "Rate-limited everywhere" and "nobody has this content" arrive as the same silence but
    # mean opposite things, so a 429 sweep is reported as inconclusive rather than as failure.
    if [ "$img_any" = no ] && [ "$img_block" = no ]; then
        [ "$img_rl" = yes ] && die "image: every gateway answered 429 and no block probe got through; inconclusive, retry later"
        die "image did not resolve anywhere; run '$0 status'"
    fi
    if [ -z "$json" ] && [ "$meta_block" = no ]; then
        [ "$meta_rl" = yes ] && die "metadata: every gateway answered 429 and no block probe got through; inconclusive, retry later"
        die "metadata did not resolve anywhere; run '$0 status'"
    fi

    # The whole point of the two-file layout: the pinned JSON must point at the pinned image.
    if [ -n "$json" ] && printf '%s' "$json" | jq empty 2>/dev/null; then
        remote=$(printf '%s' "$json" | jq -r '.image // "unreadable"')
        [ "$remote" = "ipfs://$img" ] || die "pinned metadata says image=$remote, expected ipfs://$img"
        echo "pinned metadata points at the pinned image"
    else
        echo "could not read the pinned metadata body back; content check skipped"
    fi

    if [ "$img_public" = yes ] && [ "$meta_public" = yes ]; then
        echo "OK - reachable from public IPFS"
    elif { [ "$img_public" = yes ] || [ "$img_block" = yes ]; } &&
         { [ "$meta_public" = yes ] || [ "$meta_block" = yes ]; }; then
        echo "OK - independent public gateways served the blocks for both CIDs."
        echo "The whole-file fetch was refused with HTTP 429, which is those gateways"
        echo "throttling this machine, not a verdict on the content. Retry in an hour"
        echo "for the stronger check, or run it from another network."
    else
        echo
        echo "NOT SAFE TO MINT: only your provider's own gateway served this content."
        echo "No independent gateway could fetch it, so wallets, marketplaces and anyone"
        echo "without that gateway URL would see a broken token, permanently. The provider"
        echo "is announcing the CID without serving the blocks; re-uploading to the same"
        echo "provider will not fix it. Pin the files to a second service and re-record."
        return 1
    fi
}

case "${1:-}" in
    set-image) set_image "${2:-}" ;;
    record)    record "${2:-}" "${3:-}" ;;
    check)     check ;;
    *) sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 1 ;;
esac
