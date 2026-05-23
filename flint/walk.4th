\ flint/walk.4th — discover .4th files under a root directory.
\
\ We shell out to `find` rather than reimplementing a Forth directory walker:
\ `find -type f -name '*.4th' -not -path '*/build/*'` is one line and well-
\ understood. The list is written to a temp file, then read back.

require flint/util.4th

2variable flint.walk-tmpfile
s" /tmp/flint-files.tmp" flint.walk-tmpfile 2!

\ Append a string to a buffer at the given offset; return new offset.
: flint.append { buf off s su -- new-off }
    s buf off + su move
    off su + ;

\ Build "find <root> -type f -name '*.4th' -not -path '*/build/*' > <tmp>"
\ and run it.
: flint.walk-collect ( root-a root-u -- )
    1024 allocate throw { buf }
    buf 0 s" find "
        flint.append { off }
    buf off 2swap                                  \ ( buf off root-a root-u )
        flint.append to off
    buf off s"  -type f -name '*.4th' -not -path '*/build/*' > "
        flint.append to off
    buf off flint.walk-tmpfile 2@
        flint.append to off
    buf off system
    buf free throw ;

\ Read the temp file and call xt ( path-a path-u -- ) for every line.
: flint.walk-foreach { xt -- }
    flint.walk-tmpfile 2@ r/o open-file throw { fid }
    pad 4096 fid read-line throw                   ( u-read more? )
    begin
        while                                      ( u-read )
        pad swap xt execute                        ( -- )
        pad 4096 fid read-line throw               ( u-read more? )
    repeat
    drop                                           \ drop trailing u-read
    fid close-file throw ;
