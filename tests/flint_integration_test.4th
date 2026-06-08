\ tests/flint_integration_test.4th
\
\ In-process mirror of tests/flint_integration_test.sh so fcov run fmix
\ test sees walk / scan / collect / report and version-check warn paths.

: flint.test-setup-fpath
    s" FLINT_HOME" getenv 2dup nip 0= IF
        cr ." [SKIP] flint_integration_test needs FLINT_HOME" cr
        2drop 0 (bye)
    THEN
    fpath also-path ;
flint.test-setup-fpath

s" forth-packages/ttester/1.2.1/ttester.4th" included
s" forth-packages/ttester/1.2.1/ttester-ext.4th" included

require flint/util.4th
require flint/scan.4th
require flint/collect.4th
require flint/walk.4th
require flint/report.4th

2variable flint-ver-data
s" 0.2.2" flint-ver-data 2!

require flint/version-check.4th

2variable flint.arg
s" ." flint.arg 2!

0 #ERRORS !

: flint.test-lint ( path-a path-u -- warns )
    flint.records-clear
    flint.arg 2!
    flint.check-required-version
    flint.arg 2@ flint.walk-collect
    ['] flint.scan-file flint.walk-foreach
    flint.report-duplicates
    flint.warn-count @ ;

T{ s" tests/fixtures/no_dupes" flint.test-lint -> 0 }T
T{ s" tests/fixtures/with_dupes" flint.test-lint -> 2 }T

: flint.test-warn-too-old
    0 flint.legacy-self-dep? !
    s" ~> 99.0" flint.set-required-req
    flint.check-required-version ;

: flint.test-warn-legacy
    -1 flint.legacy-self-dep? !
    s" ~> 0.2" flint.set-required-req
    flint.check-required-version
    0 flint.legacy-self-dep? ! ;

: flint.test-warn-invalid
    0 flint.legacy-self-dep? !
    s" not-a-req" flint.set-required-req
    flint.check-required-version ;

T{ flint.test-warn-too-old -> }T
T{ flint.test-warn-legacy -> }T
T{ flint.test-warn-invalid -> }T
T{ s" foo.4th" s" .4th" flint.ends-with? -> true }T
T{ s" foo.txt" s" .4th" flint.ends-with? -> false }T
T{ s" Foo" s" foo" flint.ci-compare -> 0 }T
T{ s" abc" s" xyz" flint.ci-compare 0<> -> true }T

: report
    #ERRORS @ 0= IF
        cr ." flint_integration_test ok" cr
    ELSE
        cr ." flint_integration_test FAILED: " #ERRORS @ . ." errors" cr
        1 (bye)
    THEN ;
report
bye
