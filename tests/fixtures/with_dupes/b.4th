\ tests/fixtures/with_dupes/b.4th — collides with a.4th on `my-var`
\ and `shared-thing`.

variable my-var

: shared-thing ( -- )  ." shared from b" ;

\ This `s" : not-a-defn"` string should not register `not-a-defn`.
: noisy-string  s" : not-a-defn" type ;

\ :noname must NOT be reported (no name).
:noname ." anon" ;

create my-table 16 cells allot

: only-in-b ( -- )  ." only-in-b" ;
