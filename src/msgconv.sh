#!/bin/sh

set -e -u -C

MAX_LINES=23
LINE_LENGTH=40
INDENT='        '

main() {
    inf=$1; shift
    lines=$(wc -l < "$inf")
    startLine=$(( MAX_LINES/2 - lines/2 ))

    exec <"$inf"

    number=$startLine
    while read -r line; do
        number=$(( number + 1 ))
        handleLine "$number" "$line"
    done
    printf '%s; end of message\n' "$INDENT"
    printf '%s.byte $00, $00\n' "$INDENT"
}

handleLine() {
    number=$1; shift
    line=$1; shift
    if test -z "$line"; then
        printf '%s; blank line here\n' "$INDENT"
        return
    fi

    baseAddr=$(getLineBase "$number")
    charCount=$(echo "$line" | wc -c)
    charCount=$(( charCount - 1 ))  # don't count newline char
    addr=$(( baseAddr + LINE_LENGTH/2 - charCount/2 - 1 ))
    if test "$addr" -lt "$baseAddr"; then
        addr=$baseAddr
    fi
    addrLo=$(( addr % 256 ))
    addrHi=$(( addr >> 8 ))

    printf '%s.byte $%02X, $%02X\n' "$INDENT" "$addrLo" "$addrHi"
    printf '%sscrcode "%s"\n' "$INDENT" "$line"
    printf '%s.byte $00\n' "$INDENT"
}

getLineBase() {
    # Translated from BASCALC in Apple ][ monitor code
    n=$1; shift
    x=$(( (n & 24) | ( (n % 2) << 7) ))
    echo "$(( ( ( (n>>1) & 3 | 4) << 8) | ( (x | x << 2) & 255) ))"
}

main "$@"
exit 0
