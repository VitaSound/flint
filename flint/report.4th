\ flint/report.4th — pretty-print collected duplicate warnings.
\
\ We don't want O(N²) lines of "name defined in X and Y, name defined in
\ X and Z, name defined in Y and Z" — group by name and print each name
\ once with the full list of files.
\
\ Implementation: instead of using flint.find-duplicates' pairwise hook,
\ walk the records list ourselves, mark each record as «reported», and for
\ every still-unreported record gather all matching records into one block.

require flint/util.4th
require flint/collect.4th

variable flint.warn-count
0 flint.warn-count !

\ Marker: a 6th cell on each record indicating "reported".  We can't extend
\ the struct after the fact; instead, allocate a parallel marker buffer.
\ For simplicity we use an in-place trick: walk records once collecting
\ unique names into a small array, and for each, list the files.
\
\ For now: a brute-force two-loop approach — O(N²) which is fine at <1000
\ definitions per project.

\ Has any earlier record (in list order) the same name? If yes, we already
\ reported it as part of the earlier group, so skip.
: flint.earlier-with-name? { rec -- f }
    flint.records-head @ { cur }
    begin cur rec <> while
        cur flint.rec-name rec flint.rec-name flint.ci-compare 0= IF
            true EXIT
        THEN
        cur flint.rec-next to cur
    repeat
    false ;

\ Count records that share rec's name (always >= 1, includes rec itself).
: flint.count-with-name { rec -- n }
    0 flint.records-head @ { cur }
    begin cur while
        cur flint.rec-name rec flint.rec-name flint.ci-compare 0= IF 1+ THEN
        cur flint.rec-next to cur
    repeat ;

\ Print the full group for rec (rec's name + every file that defines it).
: flint.print-group-for { rec -- }
    cr s" [WARN] duplicate word `" type
    rec flint.rec-name type
    s" ` defined in:" type cr
    flint.records-head @ { cur }
    begin cur while
        cur flint.rec-name rec flint.rec-name flint.ci-compare 0= IF
            s"     " type cur flint.rec-file type cr
        THEN
        cur flint.rec-next to cur
    repeat ;

\ Public: walk records, print one warning per *true* duplicate group
\ (size >= 2).  Skip singletons and don't reprint groups already covered
\ via an earlier record.
: flint.report-duplicates
    flint.records-head @ { rec }
    begin rec while
        rec flint.earlier-with-name? 0= IF
            rec flint.count-with-name 1 > IF
                rec flint.print-group-for
                1 flint.warn-count +!
            THEN
        THEN
        rec flint.rec-next to rec
    repeat ;
