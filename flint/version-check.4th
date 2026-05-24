\ flint/version-check.4th — read the project's `./package.4th` and warn
\ (don't fail) if the installed flint doesn't satisfy
\ `key-value flint <req>`.
\
\ The requirement grammar is the same as fmix's, and as of flint 0.2.1
\ all parsing & matching is delegated to the standalone `fsemver`
\ package (vendored at ./forth-packages/fsemver/0.1.0/). flint and fmix
\ now share one operator engine — see fsemver's README for the full
\ table (~>, >=, ==, >, <, <=, bare X.Y.Z).
\
\ Examples:
\
\   key-value flint ~> 0.2          \ MAJOR pinned:        >= 0.2.0  and  < 1.0.0
\   key-value flint ~> 0.2.3        \ MAJOR+MINOR pinned:  >= 0.2.3  and  < 0.3.0
\   key-value flint >= 0.2.0        \ minimum, no upper bound
\   key-value flint 0.2.0           \ bare:                >= 0.2.0
\
\ Unlike fmix, a mismatch is *warn-only*: flint is a linter, not a gate.
\ A future major bump may want to make this strict, but for now we just
\ surface the situation so the project author can decide what to do.
\
\ The legacy pre-0.2 form (`key-list dependencies flint <ver>`) is also
\ detected and surfaced as a warning, with a hint pointing at the new
\ syntax.
\
\ This file expects `flint-ver-data` (a 2variable holding the installed
\ flint version, e.g. "0.2.1") to be set by `flint.4th` before we are
\ loaded.

require flint/util.4th
require forth-packages/fsemver/0.1.0/fsemver.4th

\ --- Stored state -------------------------------------------------------

2variable flint.required-req      0 0 flint.required-req 2!
variable  flint.legacy-self-dep?  0 flint.legacy-self-dep? !

: flint.set-required-req ( a u -- )
    flint.str-dup flint.required-req 2! ;

\ --- Throw-away DSL parser for ./package.4th ---------------------------
\
\ MARKER scope: forth-package / end-forth-package / key-value / key-list
\ and the scan word itself are throwaway. After MARKER expiration only
\ the variables they wrote into survive — the public API below picks
\ them up.

MARKER flint.discard-vercheck-parser

: forth-package ;
: end-forth-package ;

: key-value
    parse-name 2dup s" flint" compare 0= IF
        2drop 0 parse fsemver.strip-ws flint.set-required-req
    ELSE
        2drop 0 parse 2drop
    THEN ;

: key-list
    parse-name 2dup s" dependencies" compare 0= IF
        2drop
        parse-name 2dup s" flint" compare 0= IF
            2drop true flint.legacy-self-dep? !
            0 parse 2drop
        ELSE
            2drop 0 parse 2drop
        THEN
    ELSE
        2drop 0 parse 2drop
    THEN ;

\ Build absolute "$(cwd)/package.4th" so `included` doesn't depend on
\ gforth's "./ is relative to the source file's dir" convention.
: flint.cwd-package-path { -- a u }
    pad 4096 get-dir { pa pu }
    pa pu s" /package.4th" flint.str-concat ;

: flint.maybe-scan-package
    flint.cwd-package-path 2dup file-status nip 0= IF
        2dup included
    THEN
    drop free throw ;

flint.maybe-scan-package

flint.discard-vercheck-parser

\ --- Public API (defined *after* MARKER expiration so they survive) ----

: flint.warn-legacy
    cr s" [WARN] Project's package.4th uses pre-0.2 form:" type cr
    s"            key-list dependencies flint <version>" type cr
    s"        flint is a runtime/tooling requirement, not a library." type cr
    s"        Recommended migration (one-line edit):" type cr
    s"            key-value flint ~> <X.Y>" type cr ;

: flint.warn-invalid-req
    cr s" [WARN] Invalid flint version requirement in package.4th:" type cr
    s"            key-value flint " type flint.required-req 2@ type cr
    s"        Expected one of: ~> X.Y, ~> X.Y.Z, >= X.Y.Z, == X.Y.Z," type cr
    s"                         >  X.Y.Z, <  X.Y.Z, <= X.Y.Z, or bare X.Y.Z" type cr ;

: flint.warn-too-old
    cr s" [WARN] This project requires flint " type
    flint.required-req 2@ type
    s" , but you have " type flint-ver-data 2@ type cr
    s"        Continuing anyway — flint won't block your lint." type cr ;

: flint.check-required-version
    flint.legacy-self-dep? @ IF flint.warn-legacy EXIT THEN
    flint.required-req 2@ nip 0= IF EXIT THEN

    flint.required-req 2@ fsemver.parse-req { rop rma rmi rpa rok }
    rok 0= IF flint.warn-invalid-req EXIT THEN

    flint-ver-data 2@ fsemver.parse-version-parts drop { sma smi spa }
    rma rmi rpa rop sma smi spa fsemver.req-matches? 0= IF
        flint.warn-too-old EXIT
    THEN ;
