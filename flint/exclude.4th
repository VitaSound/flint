\ flint/exclude.4th — opt-out path filter for the walker.
\
\ In the project's ./package.4th:
\
\     key-list flint-exclude fsys/j1a/extra-min.4th
\     key-list flint-exclude some/dir/
\
\ A path is excluded when it contains the pattern as a substring.
\ Use a file path to skip one source, or a directory prefix for a tree.
\ Intentional parallel dictionaries (j1a vs j1b extras) use this.

require flint/util.4th
require ../forth-packages/fenum/0.1.1/fenum-bs.4th

begin-structure flint-excl%
    field: flint.excl-pat-a
    field: flint.excl-pat-u
end-structure

variable flint.excludes    ulist-new flint.excludes !

: flint.free-excl ( e -- )
    dup flint.excl-pat-a @ free throw
    free throw ;

: flint.excludes-clear
    ['] flint.free-excl flint.excludes @ ulist-each
    flint.excludes @ ulist-clear ;

: flint.exclude-add { p-a p-u -- }
    p-u 0= IF EXIT THEN
    flint-excl% allocate throw { e }
    p-a p-u flint.str-dup { na nu }
    na e flint.excl-pat-a !
    nu e flint.excl-pat-u !
    e flint.excludes @ ulist-add ;

: flint.contains? { hay-a hay-u needle-a needle-u -- f }
    hay-u needle-u < IF false EXIT THEN
    hay-u needle-u - 1+ 0 ?do
        hay-a i + needle-u needle-a needle-u compare 0= IF
            true unloop EXIT
        THEN
    loop
    false ;

variable flint.excl-target-a
variable flint.excl-target-u
variable flint.excl-match?

: flint.excl-step { e -- }
    flint.excl-match? @ IF EXIT THEN
    flint.excl-target-a @ flint.excl-target-u @
    e flint.excl-pat-a @ e flint.excl-pat-u @
    flint.contains? IF -1 flint.excl-match? ! THEN ;

: flint.path-excluded? { a u -- f }
    a flint.excl-target-a !
    u flint.excl-target-u !
    0 flint.excl-match? !
    ['] flint.excl-step flint.excludes @ ulist-each
    flint.excl-match? @ ;

MARKER flint.discard-excl-parser

: forth-package ;
: end-forth-package ;
: key-value parse-name 2drop 0 parse 2drop ;

: key-list
    parse-name 2dup s" flint-exclude" compare 0= IF
        2drop
        parse-name dup IF flint.exclude-add ELSE 2drop THEN
        0 parse 2drop
    ELSE
        2drop 0 parse 2drop
    THEN ;

: flint.cwd-package-path { -- a u }
    pad 4096 get-dir { pa pu }
    pa pu s" /package.4th" flint.str-concat ;

: flint.maybe-scan-excludes
    flint.cwd-package-path 2dup file-status nip 0= IF
        2dup included
    THEN
    drop free throw ;

flint.maybe-scan-excludes

flint.discard-excl-parser
