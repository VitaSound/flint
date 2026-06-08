\ flint/report.4th — group records by name, print one WARN per real
\ duplicate (>= 2 distinct file mentions for the same name).
\
\ fenum's ulist-each only carries an xt — no closures — so we pass the
\ «current record» between callbacks via a module-local variable.

require flint/util.4th
require flint/collect.4th

\ --- Private state used to relay context across ulist-each callbacks ----

variable flint.cur-rec        \ record whose group we're currently building
variable flint.cur-count      \ running count of matches for cur-rec
variable flint.seen-earlier?  \ was cur-rec's name already seen before it?
variable flint.passed-cur?    \ have we walked past cur-rec in this scan?

\ --- Predicates plugged into ulist-each ---------------------------------

: flint.tick-if-name-matches ( rec -- )
    flint.rec-name@
    flint.cur-rec @ flint.rec-name@
    flint.ci-compare 0= IF 1 flint.cur-count +! THEN ;

: flint.print-if-name-matches ( rec -- )
    dup flint.rec-name@
    flint.cur-rec @ flint.rec-name@
    flint.ci-compare 0= IF
        s"     " type flint.rec-file@ type cr
    ELSE
        drop
    THEN ;

\ ulist-each has no early-exit, so we walk the *whole* list and use
\ flint.passed-cur? to logically «stop» once we've gone past cur-rec.
\ Only records strictly earlier than cur-rec are checked for a name match.
: flint.flag-earlier-match ( rec -- )
    flint.passed-cur? @ IF drop EXIT THEN
    dup flint.cur-rec @ = IF
        -1 flint.passed-cur? !
        drop EXIT
    THEN
    flint.seen-earlier? @ IF drop EXIT THEN
    flint.rec-name@
    flint.cur-rec @ flint.rec-name@
    flint.ci-compare 0= IF -1 flint.seen-earlier? ! THEN ;

\ --- Driver -------------------------------------------------------------

: flint.report-one-group ( rec -- )
    flint.cur-rec !
    0 flint.seen-earlier? !
    0 flint.passed-cur? !
    ['] flint.flag-earlier-match flint.records-each
    flint.seen-earlier? @ IF EXIT THEN

    0 flint.cur-count !
    ['] flint.tick-if-name-matches flint.records-each
    flint.cur-count @ 1 > IF
        cr s" [WARN] duplicate word `" type
        flint.cur-rec @ flint.rec-name@ type
        s" ` defined in:" type cr
        ['] flint.print-if-name-matches flint.records-each
        1 flint.warn-count +!
    THEN ;

: flint.report-duplicates
    ['] flint.report-one-group flint.records-each ;
