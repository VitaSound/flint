\ tests/fixtures/with_dupes/a.4th — intentional fixture
\ Two words defined here also live in b.4th — flint must warn.

: only-in-a ( -- )  ." only-in-a" ;

variable my-var

: shared-thing ( -- )  ." shared from a" ;

\ comment containing : pretend-defining-word
\ should not be picked up.

: ( something-with-paren ) actually-ignored ;       \ : inside () followed by name → still a defining word
: also-from-a ( -- )   \ unique
   ." also-from-a" ;
