\ flint/util.4th — small string + memory helpers used across flint.

[IFUNDEF] flint.str-dup

: flint.str-dup { a u -- a-new u }
    u allocate throw { mem }
    a mem u move
    mem u ;

: flint.str-concat { a1 u1 a2 u2 -- a3 u3 }
    u1 u2 + allocate throw { mem }
    a1 mem u1 move
    a2 mem u1 + u2 move
    mem u1 u2 + ;

: flint.str-free ( a u -- )
    drop dup IF free throw ELSE drop THEN ;

: flint.to-lower ( c -- c' )
    dup [char] A [char] Z 1+ within IF
        [char] a [char] A - +
    THEN ;

\ Case-insensitive compare; 0 = equal, non-zero otherwise (sign not used).
: flint.ci-compare { a1 u1 a2 u2 -- n }
    u1 u2 <> IF u1 u2 - EXIT THEN
    u1 0 ?do
        a1 i + c@ flint.to-lower
        a2 i + c@ flint.to-lower
        <> IF 1 unloop EXIT THEN
    loop
    0 ;

\ Returns true if a u ends with suffix s su.
: flint.ends-with? { a u s su -- f }
    u su < IF false EXIT THEN
    a u su - + su s su compare 0= ;

[THEN]
