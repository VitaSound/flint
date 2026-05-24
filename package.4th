\ Follows theforth.net publishing guidelines:
\   https://theforth.net/guidelines
\ Order: mandatory meta keys first (name, version, license, main),
\ optional metadata (description, tags), dependencies last.
forth-package
    key-value name flint
    key-value version 0.2.1
    key-value description Forth source linter: warns on duplicate word definitions across files and dependencies
    key-value license COPL
    key-value main flint.4th
    key-value fmix ~> 0.7
    key-list tags linter
    key-list tags duplicate-definitions
    key-list tags gforth
    key-list dependencies fsemver git https://github.com/VitaSound/fsemver tag 0.1.0
    key-list dependencies fenum git https://github.com/VitaSound/fenum tag 0.1.1
    key-list dependencies ttester git https://github.com/VitaSound/ttester tag 1.2.0
end-forth-package