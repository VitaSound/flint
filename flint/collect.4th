\ flint/collect.4th — accumulate (file, word) records from flint/scan.4th
\ and report cross-file duplicates.

require flint/util.4th
require flint/scan.4th

\ --- Record list ----------------------------------------------------------
\
\ A single linked list of records. Memory layout (cells):
\   0: next      pointer (0 = end)
\   1: file-a    pointer to allocated copy of source path
\   2: file-u    length
\   3: name-a    pointer to allocated copy of word name
\   4: name-u    length

5 cells constant flint.rec-size

variable flint.records-head
0 flint.records-head !

variable flint.records-count
0 flint.records-count !

: flint.records-clear
    flint.records-head @
    begin dup while
        dup @ swap                   ( next cur )
        dup cell+        @ free throw  \ file-a
        dup 3 cells + @ free throw  \ name-a
        free throw
    repeat drop
    0 flint.records-head !
    0 flint.records-count ! ;

\ Push a record onto the head of the list.
: flint.record-define { file-a file-u name-a name-u -- }
    flint.rec-size allocate throw { rec }
    file-a file-u flint.str-dup { fa fu }
    name-a name-u flint.str-dup { na nu }
    flint.records-head @ rec !
    fa rec 1 cells + !
    fu rec 2 cells + !
    na rec 3 cells + !
    nu rec 4 cells + !
    rec flint.records-head !
    1 flint.records-count +! ;

\ Wire the scanner's event hook to our recorder.
:noname flint.record-define ; is flint.on-defined-word

\ --- Accessors ------------------------------------------------------------

: flint.rec-next ( rec -- next )       @ ;
: flint.rec-file ( rec -- a u )        cell+        2@ swap ;
: flint.rec-name ( rec -- a u )        3 cells + 2@ swap ;

\ Walk all records, applying xt ( file-a file-u name-a name-u -- ) to each.
: flint.records-foreach { xt -- }
    flint.records-head @ { node }
    begin node while
        node flint.rec-file
        node flint.rec-name
        xt execute
        node flint.rec-next to node
    repeat ;

\ --- Duplicate detection --------------------------------------------------
\
\ For every pair of records with matching name (case-insensitive), call
\ `flint.on-duplicate ( name-a name-u file1-a file1-u file2-a file2-u -- )`.
\ Self-pairs and ordered duplicates (we report A,B but not B,A) are avoided
\ by only pairing each node with strictly later nodes in the list.

defer flint.on-duplicate     \ default = no-op
:noname 2drop 2drop 2drop ; is flint.on-duplicate

: flint.find-duplicates
    flint.records-head @ { a }
    begin a while
        a flint.rec-next { b }
        begin b while
            a flint.rec-name b flint.rec-name flint.ci-compare 0= IF
                a flint.rec-name
                a flint.rec-file
                b flint.rec-file
                flint.on-duplicate
            THEN
            b flint.rec-next to b
        repeat
        a flint.rec-next to a
    repeat ;
