\ flint/walk.4th — pure-Forth recursive directory walker.
\
\ Earlier versions shelled out to `find` and piped the listing through
\ a /tmp file. That worked, but it leaked a hard dependency on a POSIX
\ host into what is otherwise a portable Forth tool. This implementation
\ uses gforth's own `open-dir` / `read-dir` / `close-dir` primitives, so
\ flint can run anywhere a host Forth provides equivalents.
\
\ The public API is unchanged:
\
\   flint.walk-collect ( root-a root-u -- )
\       Remember the root we will walk. Just stores the path; the actual
\       traversal happens lazily inside walk-foreach.
\
\   flint.walk-foreach { xt -- }
\       Walk the remembered root recursively and call
\       `xt ( path-a path-u -- )` for every regular file whose name ends
\       in `.4th`. Path strings handed to xt live on the heap and are
\       freed immediately after xt returns — xt must dup what it wants
\       to keep.
\
\ Skipped entries:
\   - empty names (defensive),
\   - any name starting with '.'  (covers `.`, `..`, `.git`, hidden …),
\   - directories named exactly `build` (project build output),
\   - directories named exactly `forth-packages` when FLINT_PROJECT_ONLY=1.

require flint/util.4th

2variable flint.walk-root      0 0 flint.walk-root 2!
variable  flint.walk-xt        0 flint.walk-xt !

256 constant flint.walk-name-max
create flint.walk-name-buf flint.walk-name-max allot

: flint.walk-skip? { a u -- f }
    u 0= IF true EXIT THEN
    a c@ [char] . = IF true EXIT THEN
    a u s" build" compare 0= IF true EXIT THEN
    flint.project-only? @ IF
        a u s" forth-packages" compare 0= IF true EXIT THEN
    THEN
    false ;

\ Probe a path: try to open it as a directory. On success we leave the
\ dir handle on the stack (caller decides whether to keep it or close
\ and recurse); on failure we leave just `false`.
: flint.walk-try-dir ( a u -- dirid true | false )
    open-dir IF drop false EXIT THEN
    true ;

\ Allocate root + "/" + name and return the new string.
: flint.walk-join { root-a root-u name-a name-u -- p-a p-u }
    root-u name-u + 1+ allocate throw { buf }
    root-a buf root-u move
    [char] / buf root-u + c!
    name-a buf root-u 1+ + name-u move
    buf root-u name-u + 1+ ;

\ Forward declaration so the implementation can recurse without
\ relying on `recurse` (which interacts awkwardly with mid-definition
\ local frames).
defer flint.walk-dir-rec

: flint.walk-dir-impl { path-a path-u -- }
    path-a path-u open-dir throw { dirid }
    begin
        flint.walk-name-buf flint.walk-name-max dirid read-dir throw
    while                                          ( u-read )
        flint.walk-name-buf swap                   ( n-a n-u )
        2dup flint.walk-skip? IF
            2drop
        ELSE
            { n-a n-u }
            path-a path-u n-a n-u flint.walk-join { c-a c-u }
            c-a c-u flint.walk-try-dir IF          ( dirid )
                close-dir throw
                c-a c-u flint.walk-dir-rec
            ELSE
                c-a c-u s" .4th" flint.ends-with? IF
                    c-a c-u flint.walk-xt @ execute
                THEN
            THEN
            c-a free throw
        THEN
    repeat
    drop                                           \ trailing u-read
    dirid close-dir throw ;

' flint.walk-dir-impl is flint.walk-dir-rec

: flint.walk-collect ( root-a root-u -- )
    flint.walk-root 2@ drop ?dup IF free throw THEN
    flint.str-dup flint.walk-root 2! ;

: flint.walk-foreach { xt -- }
    xt flint.walk-xt !
    flint.walk-root 2@ flint.walk-dir-rec ;
