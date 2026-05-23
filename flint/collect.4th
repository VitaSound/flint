\ flint/collect.4th — accumulate (file, word) records produced by
\ flint/scan.4th and expose them for the reporter.
\
\ Storage: fenum's ulist (begin-structure backend). Each record is its
\ own heap-allocated struct holding two heap-allocated strings.

require flint/util.4th
require flint/scan.4th
require ../forth-packages/fenum/0.1.1/fenum-bs.4th

\ One record per (file, word) hit.
begin-structure flint-rec%
    field: rec-file-a
    field: rec-file-u
    field: rec-name-a
    field: rec-name-u
end-structure

variable flint.records       \ holds the ulist for this session
ulist-new flint.records !

variable flint.records-count
0 flint.records-count !

\ --- Cleanup --------------------------------------------------------------

\ Per-record cleanup, plugged into ulist-each.
: flint.free-rec ( rec -- )
    dup rec-file-a @ free throw
    dup rec-name-a @ free throw
    free throw ;

: flint.records-clear
    ['] flint.free-rec flint.records @ ulist-each
    flint.records @ ulist-clear
    0 flint.records-count ! ;

\ --- Recording ------------------------------------------------------------

: flint.record-define { file-a file-u name-a name-u -- }
    flint-rec% allocate throw { rec }
    file-a file-u flint.str-dup { fa fu }
    name-a name-u flint.str-dup { na nu }
    fa rec rec-file-a !
    fu rec rec-file-u !
    na rec rec-name-a !
    nu rec rec-name-u !
    rec flint.records @ ulist-add
    1 flint.records-count +! ;

\ Wire scanner → collector.
:noname flint.record-define ; is flint.on-defined-word

\ --- Accessors / iteration ------------------------------------------------

: flint.rec-name@ ( rec -- a u )  dup rec-name-a @ swap rec-name-u @ ;
: flint.rec-file@ ( rec -- a u )  dup rec-file-a @ swap rec-file-u @ ;

\ ulist-each helper for callers that don't want to know about fenum.
: flint.records-each ( xt -- )    flint.records @ ulist-each ;
