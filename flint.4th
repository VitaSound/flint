\ flint.4th — entry point for the flint linter.
\
\ flint is a tiny linter for Forth source trees. The first (and only) check
\ is «duplicate word definitions across .4th files, including dependencies».
\
\ Usage:
\   flint              — lint the current directory (warns, never errors)
\   flint help         — show usage
\   flint version      — show version
\   flint lint [path]  — lint the given directory (default ".")
\
\ All warnings go to stdout. Exit code is always 0 — flint is a hint,
\ not a gate. (CI users who want hard failures can grep the output.)

require flint/util.4th
require flint/scan.4th
require flint/collect.4th
require flint/walk.4th
require flint/report.4th
\ flint/version-check.4th uses `flint-ver-data` — it's brought into scope
\ a few lines below, then we include version-check after that.

\ --- Self-version (read from package.4th) ---------------------------------

2variable flint-ver-data
s" unknown" flint-ver-data 2!

[UNDEFINED] flint-home-path [IF]
: flint-home-path ( -- a u )
    s" FLINT_HOME" getenv 2dup nip IF EXIT THEN
    2drop s" HOME" getenv s" /flint" flint.str-concat ;
[THEN]

\ Throwaway parser for package.4th — captures `key-value version <X>`.
MARKER flint.discard-ver-parser

: forth-package ;
: end-forth-package ;
: key-list 0 parse 2drop ;
: key-value
    parse-name s" version" compare 0= IF
        parse-name flint.str-dup flint-ver-data 2!
    ELSE
        0 parse 2drop
    THEN ;

: flint.read-self-version
    flint-home-path s" /package.4th" flint.str-concat { buf bu }
    buf bu 2dup file-status nip 0= IF
        included
    ELSE
        2drop
    THEN
    buf free throw ;

flint.read-self-version

flint.discard-ver-parser

\ Version-check parser uses its own throwaway scope; load *after* the
\ self-version parser is gone to avoid colliding key-value/key-list defs.
require flint/version-check.4th

\ --- Argument parsing -----------------------------------------------------

2variable flint.cmd
2variable flint.arg
s" " flint.cmd 2!
s" " flint.arg 2!

: flint.read-args
    s" FLINT_CMD" getenv 2dup nip IF
        flint.str-dup flint.cmd 2!
    ELSE
        2drop s" lint" flint.cmd 2!
    THEN
    s" FLINT_ARG" getenv 2dup nip IF
        flint.str-dup flint.arg 2!
    ELSE
        2drop s" ." flint.arg 2!
    THEN ;

\ --- Commands -------------------------------------------------------------

: flint.help
    cr s" flint v" type flint-ver-data 2@ type
    s"  — duplicate-definition linter for Forth source trees" type cr
    s" Usage: flint <command> [args]" type cr
    s" Commands:" type cr
    s"    lint [path]    - Lint .4th files under path (default: .)" type cr
    s"    version        - Show version" type cr
    s"    help           - Show this help" type cr cr
    s" Notes:" type cr
    s"    - Warnings go to stdout; exit code is always 0." type cr
    s"    - build/ subdirectories are skipped." type cr
    s"    - First-pass implementation: ignores conditional compilation," type cr
    s"      [IFDEF]/[IFUNDEF] guards, and per-version dedup of dependencies." type cr
    s"      A duplicate in those situations is still surfaced — review and" type cr
    s"      whitelist as needed." type cr cr ;

: flint.version
    cr s" ** (flint) v" type flint-ver-data 2@ type cr cr ;

: flint.lint
    flint.check-required-version
    flint.records-clear
    flint.arg 2@ flint.walk-collect
    ['] flint.scan-file flint.walk-foreach
    cr s" * flint: scanned " type
    flint.records-count @ . s" word definitions" type cr
    flint.report-duplicates
    cr s" * flint: " type flint.warn-count @ . s" duplicate group(s) reported." type cr ;

: flint-dispatch
    flint.read-args
    flint.cmd 2@ s" lint"    compare 0= IF flint.lint    EXIT THEN
    flint.cmd 2@ s" version" compare 0= IF flint.version EXIT THEN
    flint.cmd 2@ s" help"    compare 0= IF flint.help    EXIT THEN
    cr s" Unknown command: " type flint.cmd 2@ type cr
    flint.help
    1 (bye) ;

flint-dispatch
0 (bye)
