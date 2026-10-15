#!/bin/bash
set -eu
set -o pipefail

if [ $# -ne 3 ]
then
	echo "Usage: $0 SOURCE_FILE DEST_HOST DEST_FILE" >&2
	exit 1
fi
srcfile="$1"
dsthost="$2"
dstfile="$3"

tmpdir=$(ssh "$dsthost" mktemp -d)

printf 'sending %s to %s via %s\n' "$srcfile" "$dsthost" "$tmpdir" >&2

parallel --eta --bar --pipe-part --recend "" --block 10M -P 10 \
	--arg-file "$srcfile" \
	ssh -q -o ControlMaster=no -o RequestTTY=no "$dsthost" dd status=none of=$tmpdir/{#}
ssh "$dsthost" ls "$tmpdir" '|' sort -n '|' xargs -I N cat $tmpdir/N '>' "$dstfile" '&&' rm -r "$tmpdir"
