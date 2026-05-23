# Change Log

All notable changes to flint are documented here.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and
this project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.1] - 2026-05-24

### Changed
- Records storage refactored from a hand-rolled linked list to
  [fenum](https://github.com/VitaSound/fenum)'s `ulist` (begin-structure
  backend). Tighter ecosystem coupling, less boilerplate.
- `bin/flint`: only manipulates the terminal when stdout *is* a tty.
  Previously, when output was captured (`out=$(flint …)`) the bracketed-
  paste reset escape leaked into the captured string as literal text
  `[?2004l`. Same fix landed in `bin/fmix` (fmix 0.6.x sidebar).
- `bin/flint` header documents the shared launcher conventions
  (`$<TOOL>_HOME`, `$<TOOL>_CMD`, `$<TOOL>_ARG`) and the recommended
  `~/.bashrc` snippet.
- `package.4th`: added `tags`, fixed `license` to match the project's
  actual COPL `LICENSE` file, added explicit dependency on
  `fenum 0.1.1`.

### Added
- `README.ru.md` — полная русская версия документации.
- README links into the VitaSound tooling family (fmix / ttester / fenum).

## [0.1.0] - 2026-05-24

Initial release: **duplicate-definition linter for Forth source trees**.

### Added
- `bin/flint` — bash CLI launcher (TTY hygiene, env-var passing to gforth,
  fpath extension so `require flint/xxx.4th` resolves wherever it's run).
- `flint.4th` — entry point: read `FLINT_CMD` / `FLINT_ARG` env, dispatch
  `lint` / `version` / `help`, print self-version pulled from
  `package.4th` at load time.
- `flint/util.4th` — `str-dup`, `str-concat`, `to-lower`, case-insensitive
  `compare`, `ends-with?`.
- `flint/scan.4th` — token scanner for one `*.4th` file. Handles `\` line
  comments, `( … )` paren comments and string literals (`s"`, `."`, `c"`,
  `s\"`, `abort"`). Recognises every common defining word and emits via
  `defer flint.on-defined-word`. Correctly looks past a paren comment in
  the name slot (`: ( foo ) bar ;` → registers `bar`).
- `flint/collect.4th` — linked-list of `(file, word)` records, wired to
  `flint.on-defined-word`; reset/iterate helpers.
- `flint/walk.4th` — shells out to `find -type f -name '*.4th' -not -path
  '*/build/*'`, reads the resulting file list, runs an xt for each path.
- `flint/report.4th` — groups records by case-insensitive name, prints
  one `[WARN]` block per duplicate group of size ≥ 2. Singletons are
  silently dropped.
- `tests/flint_integration_test.sh` — drives flint against
  `tests/fixtures/{no_dupes,with_dupes}/`, asserts on the WARN lines, the
  group count, the absence of false positives, and the exit code (always 0).

### Design choices (per the original spec)
- Exit code is always 0. flint is a hint, not a gate.
- No conditional-compilation awareness — `[IFDEF]/[IFUNDEF]` guards are
  not honoured. Same word in two `[IFDEF]` branches will be reported.
- No dep-version dedup. If `forth-packages/ttester/1.1.0/` and
  `…/1.2.0/` both exist, every ttester word lights up.
- The scanner is pure text tokenising; we never *execute* the project's
  Forth.

### Roadmap (deliberately out of scope for 0.1.0)
- Branch coverage in fcov complements the duplicate check; see the
  ecosystem CHANGELOG.
- `[IFUNDEF]` whitelisting once we know how project authors actually
  want to express «this re-definition is intentional».
- HTML report alongside the plain-text output.
