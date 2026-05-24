\ tests/flint_version_check_test.4th
\
\ Thin smoke-test for flint/version-check.4th.
\
\ As of flint 0.2.1 the parsing / matching engine lives in fsemver and
\ is exhaustively covered by 71 assertions in
\ ../forth-packages/fsemver/0.1.0/tests/fsemver_test.4th. This file
\ only verifies the wiring:
\   - fsemver loads cleanly via flint/version-check.4th's require chain
\   - flint-owned state (flint.required-req, flint.legacy-self-dep?)
\     exists and is properly initialised
\   - fsemver public words are reachable from flint's load context

: flint.test-setup-fpath
    s" FLINT_HOME" getenv 2dup nip 0= IF
        cr ." [SKIP] flint_version_check_test needs FLINT_HOME env var set." cr
        2drop 0 (bye)
    THEN
    fpath also-path ;
flint.test-setup-fpath

s" forth-packages/ttester/1.2.0/ttester.4th" included
s" forth-packages/ttester/1.2.0/ttester-ext.4th" included

require flint/util.4th

\ Provide a dummy installed-version variable; version-check.4th expects
\ flint-ver-data to be defined by flint.4th in production.
2variable flint-ver-data
s" 0.2.1" flint-ver-data 2!

require flint/version-check.4th

0 #ERRORS !

\ --- Wiring: fsemver public API visible through flint's load chain ------

T{ s" 0.2.1"   fsemver.parse-version-parts -> 0 2 1 3 }T
T{ s" ~> 0.2"  fsemver.parse-req           -> 0 0 2 0 true }T
T{ s" >= 1.0"  fsemver.parse-req           -> 2 1 0 0 true }T
T{ s" garbage" fsemver.parse-req           -> 0 0 0 0 false }T

\ --- Wiring: matcher gives the expected verdict -------------------------

\ self=0.2.5 satisfies ~> 0.2
T{  0 2 0 0   0 2 5  fsemver.req-matches? -> true  }T
\ self=1.0.0 does NOT satisfy ~> 0.2
T{  0 2 0 0   1 0 0  fsemver.req-matches? -> false }T

\ --- Wiring: flint-owned state is initialised ---------------------------

\ legacy flag must start false (this fixture's package.4th, if any, uses
\ the new key-value syntax).
T{ flint.legacy-self-dep? @ -> 0 }T
\ required-req is a 2variable; len is a non-negative number.
T{ flint.required-req 2@ nip 0>= -> true }T

: report
    #ERRORS @ 0= IF
        cr ." flint_version_check_test ok" cr
    ELSE
        cr ." flint_version_check_test FAILED: " #ERRORS @ . ." errors" cr
        1 (bye)
    THEN ;
report
bye
