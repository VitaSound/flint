# Change Log

All notable changes to flint are documented here.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and
this project adheres to [Semantic Versioning](http://semver.org/).

## [0.2.3] - 2026-06-08

### Added
- `tests/flint_integration_test.4th` — in-process walk/scan/collect/report
  integration on fixtures plus version-check warn paths; raises fcov baseline
  from ~22 % to ~87 %.
- GitHub Actions CI (Gforth 0.7.9, fmix 0.7.2, `fmix test`).
- License, Ver and Cov badges in `README.md` / `README.ru.md`.

### Changed
- Pin ttester 1.2.1 in `package.4th` and version-check tests.

## [0.2.2] - 2026-05-24

### Added
- `package.4th`: declare `key-value fcov ~> 0.3` (ecosystem-wide
  coverage participation) and `key-list fcov-exclude tests/fixtures`
  so fcov reports flint code, not its fixture projects. Current
  baseline on `fcov run fmix test`: 13/59 (22 %) — most uncovered
  code (walk / scan / collect / report) is exercised by
  `flint_integration_test.sh`, a black-box harness invisible to
  `fcov`. Lifting this number is one of the headline TODOs in
  `fhdlgen/doc/ecosystem.md` § Recommendations.
- `.gitignore`: ignore `.fcov/` runtime artefacts; also reformat to
  multi-line style with `build/`, `*.swp`, `.DS_Store`.

## [0.2.1] - 2026-05-24

### Changed
- **Version-requirement engine extracted to fsemver.** The parser,
  matcher and operator constants previously living inline in
  `flint/version-check.4th` are now provided by the standalone
  [fsemver 0.1.0](https://github.com/VitaSound/fsemver) package, shared
  with fmix 0.7.1 (and any future fcov / similar tooling). No more
  cut-and-paste drift between linter and build tool.
- `flint/version-check.4th` shrinks from ~193 lines to ~115 (only the
  project-side mini-parser, the captured req string, the warning text,
  and `flint.check-required-version` itself). Internal words like
  `flint.parse-req`, `flint.req-matches?`, `flint.parse-version-parts`
  are gone — call `fsemver.parse-req` / `fsemver.req-matches?` /
  `fsemver.parse-version-parts` instead if any out-of-tree code was
  relying on them.
- Operator coverage widens transparently: `>=`, `==`, `>`, `<`, `<=`
  are accepted in `key-value flint <req>` in addition to `~>` and bare
  `X.Y.Z` (you get them for free via fsemver).

### Added
- `key-list dependencies fsemver git https://github.com/VitaSound/fsemver tag 0.1.0`
  in `package.4th`. Run `fmix packages.get` after `git pull` to fetch
  it into `forth-packages/fsemver/0.1.0/`.

### Notes
- No behaviour change for project authors. `key-value flint ~> 0.2`
  (and friends) keep working exactly as before. Legacy
  `key-list dependencies flint …` still emits the same WARN with
  migration hint.
- `tests/flint_version_check_test.4th` is now a thin smoke-test (8
  assertions) that verifies fsemver is reachable from flint's load
  chain. The full 71-case operator truth-table lives upstream in
  `forth-packages/fsemver/0.1.0/tests/fsemver_test.4th`.

## [0.2.0] - 2026-05-24

### Added
- `flint/version-check.4th` — read the project's `./package.4th` and
  warn (don't fail) if the installed flint doesn't satisfy
  `key-value flint <req>`. Same Elixir/Hex requirement grammar as
  fmix's `key-value fmix <req>`:
  ```
  key-value flint ~> 0.2          \ >=0.2.0  and  <1.0.0
  key-value flint ~> 0.2.3        \ >=0.2.3  and  <0.3.0
  key-value flint 0.2.0           \ bare = >=0.2.0
  ```
  Unlike fmix's check, mismatch is **warn-only** — flint is a linter,
  not a build gate, so the lint always runs.
- Legacy pre-0.2 `key-list dependencies flint <ver>` form is detected
  and surfaced as a WARN with a one-line migration hint.
- `tests/flint_version_check_test.4th` — 22 unit assertions for
  parser & matcher (mirrors fmix's coverage exactly).
- `tests/fixtures/{wants_future_flint,legacy_flint_dep,invalid_flint_req}/`
  and matching cases in `tests/flint_integration_test.sh` (now 11 OK
  lines; was 7) — confirm warn-only behaviour and that lint still
  finishes its work.

### Changed
- `package.4th` bumped to 0.2.0; runtime requirement on fmix is now
  expressed Elixir-style as `key-value fmix ~> 0.7` instead of the
  legacy `key-list dependencies fmix 0.6.0`.

## [0.1.1] - 2026-05-24

### Changed
- `flint/walk.4th` rewritten in pure Forth: dropped the `find` shell-out
  and the `/tmp/flint-files.tmp` round-trip in favour of gforth's own
  `open-dir` / `read-dir` / `close-dir`. flint no longer depends on any
  POSIX utility — only on a host Forth that exposes directory primitives.
  Recursion uses `defer` + `is` so we get a clean local-stack frame per
  level. Skips `.`, `..`, hidden names, and `build/` subtrees.
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
