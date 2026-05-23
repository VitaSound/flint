\ flint/scan.4th — tokenise a single .4th file and emit defining-word events.
\
\ Spec is deliberately «dumb»: a token is a whitespace-separated run of
\ characters, with comments and strings recognised so we don't mistake the
\ insides of `( ... )` or `s" ..."` for code.
\
\ Recognised defining words (case-insensitive):
\
\   :  variable 2variable fvariable
\   constant 2constant fconstant
\   value 2value fvalue
\   create defer marker
\   field field: cfield: nfield: ufield:
\   code synonym
\
\ When such a word is seen, the *next* token is treated as the name being
\ defined and reported via the deferred `flint.on-defined-word` hook.
\
\ `:noname` is explicitly skipped (no name → nothing to report).

require flint/util.4th

\ --- Scan-time mutable buffer ----------------------------------------------

2variable flint.scan-buf
variable  flint.scan-pos

: flint.scan-set ( a u -- )
    flint.scan-buf 2! 0 flint.scan-pos ! ;

: flint.scan-end? ( -- f )
    flint.scan-pos @ flint.scan-buf 2@ nip >= ;

: flint.scan-peek ( -- c|0 )
    flint.scan-end? IF 0 EXIT THEN
    flint.scan-buf 2@ drop flint.scan-pos @ + c@ ;

: flint.scan-advance ( -- )
    flint.scan-end? IF EXIT THEN
    1 flint.scan-pos +! ;

: flint.scan-skip-ws
    begin
        flint.scan-end? IF EXIT THEN
        flint.scan-peek bl > IF EXIT THEN
        flint.scan-advance
    again ;

\ Consume up to and including a newline.
: flint.scan-skip-line
    begin
        flint.scan-end? IF EXIT THEN
        flint.scan-peek 10 = IF flint.scan-advance EXIT THEN
        flint.scan-advance
    again ;

\ Consume up to (and including) the given delimiter char.
: flint.scan-skip-to-char { c -- }
    begin
        flint.scan-end? IF EXIT THEN
        flint.scan-peek c = IF flint.scan-advance EXIT THEN
        flint.scan-advance
    again ;

\ Read the next whitespace-separated token into addr-in-buffer + length.
: flint.scan-next-token ( -- a u )
    flint.scan-skip-ws
    flint.scan-end? IF 0 0 EXIT THEN
    flint.scan-buf 2@ drop flint.scan-pos @ +     ( tok-a )
    0                                              ( tok-a tok-u )
    begin
        flint.scan-end? IF EXIT THEN
        flint.scan-peek bl <= IF EXIT THEN
        1+
        flint.scan-advance
    again ;

\ --- Defining-word recognition --------------------------------------------

: flint.defining? { tok-a tok-u -- f }
    tok-a tok-u s" :"          flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" variable"   flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" 2variable"  flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" fvariable"  flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" constant"   flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" 2constant"  flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" fconstant"  flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" value"      flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" 2value"     flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" fvalue"     flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" create"     flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" defer"      flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" marker"     flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" field"      flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" field:"     flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" cfield:"    flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" nfield:"    flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" ufield:"    flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" code"       flint.ci-compare 0= IF true EXIT THEN
    tok-a tok-u s" synonym"    flint.ci-compare 0= IF true EXIT THEN
    false ;

\ String-literal openers (consume up to the matching ")
: flint.string-opener? { tok-a tok-u -- f }
    tok-a tok-u s\" s\""        compare 0= IF true EXIT THEN
    tok-a tok-u s\" .\""        compare 0= IF true EXIT THEN
    tok-a tok-u s\" c\""        compare 0= IF true EXIT THEN
    tok-a tok-u s\" s\\\""      compare 0= IF true EXIT THEN
    tok-a tok-u s\" abort\""    compare 0= IF true EXIT THEN
    false ;

\ --- Event hook -----------------------------------------------------------
\
\ Bound by the collector below; default is a no-op so scan.4th can be
\ loaded and exercised in isolation by its tests.

defer flint.on-defined-word    \ ( file-a file-u name-a name-u -- )
:noname 2drop 2drop ; is flint.on-defined-word

\ --- Whole-file scan ------------------------------------------------------

\ Like scan-next-token but skips line comments, paren comments and string
\ literals — i.e. returns the next *code* token.  Used to read the name
\ slot after a defining word so that `: ( foo ) bar ;` correctly skips
\ the paren comment and registers `bar` rather than `(`.
: flint.scan-next-code-token ( -- a u )
    begin
        flint.scan-next-token dup 0= IF EXIT THEN
        { ta tu }
        ta tu s" \" compare 0= IF
            flint.scan-skip-line
        ELSE ta tu s" (" compare 0= IF
            [char] ) flint.scan-skip-to-char
        ELSE ta tu flint.string-opener? IF
            [char] " flint.scan-skip-to-char
        ELSE
            ta tu EXIT
        THEN THEN THEN
    again ;

\ slurp the file, walk tokens, free.
: flint.scan-file { fname-a fname-u -- }
    fname-a fname-u slurp-file flint.scan-set
    begin
        flint.scan-next-token { tok-a tok-u }
        tok-u 0= IF
            flint.scan-buf 2@ drop free throw
            EXIT
        THEN
        tok-a tok-u s" \" compare 0= IF
            flint.scan-skip-line
        ELSE tok-a tok-u s" (" compare 0= IF
            [char] ) flint.scan-skip-to-char
        ELSE tok-a tok-u flint.string-opener? IF
            [char] " flint.scan-skip-to-char
        ELSE tok-a tok-u flint.defining? IF
            flint.scan-next-code-token { name-a name-u }
            name-u 0= IF
                flint.scan-buf 2@ drop free throw
                EXIT
            THEN
            fname-a fname-u name-a name-u flint.on-defined-word
        THEN THEN THEN THEN
    again ;
