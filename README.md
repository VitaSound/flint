# flint
[![License](https://img.shields.io/badge/License-COPL-red.svg)](https://raw.githubusercontent.com/VitaSound/flint/refs/heads/main/LICENSE)
[![Ver](https://img.shields.io/badge/Ver-0.2.3-green.svg)](https://github.com/VitaSound/flint/releases/tag/0.2.3)
[![Cov](https://img.shields.io/badge/Cov-87%25-green.svg)](https://github.com/VitaSound/flint/actions/workflows/ci.yml)

[Русская версия](README.ru.md)

A small linter for Forth source trees.

flint's only check (for now) is **duplicate word definitions across files,
including dependencies**. It scans every `*.4th` under the current
directory, collects every named definition (`:`, `variable`, `create`,
`defer`, `value`, `marker`, `field`, …) and prints a warning for every
name that appears in more than one file.

flint is intentionally **dumb in the first pass**:

- No conditional-compilation awareness (`[IFDEF]` / `[IFUNDEF]` are
  ignored — every `: foo …` inside any branch is counted).
- No dependency-version dedup (if you have `forth-packages/ttester/1.2.0/`
  *and* `forth-packages/ttester/1.2.1/` in your tree, you'll see warnings
  for every word ttester defines — that's the intended signal).
- No deep Forth semantics (we don't run any code; this is pure text
  tokenising with comment/string skipping).

Output is **warn-level only** — flint always exits with status 0. CI
users who want a hard failure can `grep '\[WARN\]'` and react.

Part of the [VitaSound Forth tooling
family](https://github.com/VitaSound): [fmix](https://github.com/VitaSound/fmix)
(build tool / package manager / test runner),
[ttester](https://github.com/VitaSound/ttester) (testing utility,
upstream Hayes/Ertl + VitaSound extensions),
[fenum](https://github.com/VitaSound/fenum) (universal containers,
used by flint for its records list), flint.

## Install

```bash
cd ~ && git clone git@github.com:VitaSound/flint.git
cd flint && fmix packages.get
```

## Shell setup

Add to `~/.bashrc` (or `~/.zshrc`) — **two lines for this tool only** (VitaSound convention: one tool per PATH line; do not merge with siblings):

```bash
export FLINT_HOME="<install-dir>/flint"
export PATH="$FLINT_HOME/bin:$PATH"
```

`<install-dir>` is the parent of your clones (`$HOME` if you cloned beside `~/feco`, or e.g. `/opt/vitasound` for an isolated workspace). Bulk install: [VitaSound/feco](https://github.com/VitaSound/feco) — `./scripts/clone-ecosystem.sh`. Canonical rules: [feco shell setup](https://github.com/VitaSound/feco/blob/main/docs/shell-setup.md).

Then `source ~/.bashrc` and run `flint version`.

Sibling CLI tools (fmix, fcov, fmcp, fhdlgen) each need their own two-line block — see [feco shell setup](https://github.com/VitaSound/feco/blob/main/docs/shell-setup.md).

flint requires Gforth ≥ 0.7.9 — no other OS dependencies.

## Usage

```bash
flint               # lint current dir; warn lines + summary
flint lint <path>   # lint a different dir
flint version       # print version
flint help          # print usage
```

Typical output:

```
* flint: scanned 312 word definitions

[WARN] duplicate word `module-new` defined in:
    ./fhdlgen/core/module.4th
    ./projects/old/legacy.4th

[WARN] duplicate word `ERROR` defined in:
    ./forth-packages/ttester/1.2.0/ttester.4th
    ./forth-packages/ttester/1.2.1/ttester.4th

* flint: 2 duplicate group(s) reported.
```

## Defining words recognised

```
:  variable 2variable fvariable
constant 2constant fconstant
value 2value fvalue
create defer marker
field field: cfield: nfield: ufield:
code synonym
```

Add more in `flint/scan.4th : flint.defining?`.

## Limitations / known false positives

| Situation | What flint does | Workaround |
|-----------|----------------|------------|
| Same dep at two versions in `forth-packages/` | Reports every word | Clean up old versions: `rm -rf forth-packages/<name>/<old>` |
| Re-definitions inside `[IFUNDEF] foo … [THEN]` (intentional polyfill) | Reports as duplicate | Pin the load order; consider extracting the polyfill into its own file and only loading it once |
| `:noname` lambdas | Not counted (no name → nothing to clash) | — |
| `: ( name-shadowed-by-comment ) bar ;` (paren comment in name slot) | Correctly looks past the comment and records `bar` | — |
| Words defined inside strings (`s" : not-a-defn"`) | Correctly ignored | — |

## Implementation

| File | What |
|------|------|
| `bin/flint` | bash launcher (TTY reset, env-var passing to gforth, `fpath` extension) |
| `flint.4th` | entry point: arg parsing, command dispatch |
| `flint/util.4th` | string + case helpers |
| `flint/scan.4th` | per-file token scanner with `defer flint.on-defined-word` hook |
| `flint/collect.4th` | records storage on top of [fenum](https://github.com/VitaSound/fenum)'s `ulist` (one struct per `(file, word)` pair) |
| `flint/walk.4th` | recursive directory walk using gforth's native `open-dir` / `read-dir` / `close-dir` (no shell-out to `find`) |
| `flint/report.4th` | group records by name, print one WARN per real duplicate |
| `flint/version-check.4th` | read `key-value flint <req>` from `./package.4th` and warn (don't fail) if the installed flint doesn't match. Parsing / matching delegated to [fsemver](https://github.com/VitaSound/fsemver) (shared with fmix). |

## Version pinning (`key-value flint ~> X.Y`)

A project's `package.4th` can declare a minimum flint version using the
same Elixir/Hex grammar fmix uses:

```forth
forth-package
    key-value name myproj
    key-value version 0.1.0
    key-value main myproj.4th
    key-value flint ~> 0.2
end-forth-package
```

| Form | Means |
|------|-------|
| `key-value flint ~> 0.2` | `>= 0.2.0` and `< 1.0.0` (MAJOR pinned) |
| `key-value flint ~> 0.2.3` | `>= 0.2.3` and `< 0.3.0` (MAJOR+MINOR pinned) |
| `key-value flint >= 0.2.0` | minimum, no upper bound |
| `key-value flint == 0.2.0` | exact match |
| `key-value flint >  0.2.0` | strictly greater |
| `key-value flint <  1.0.0` | strictly less |
| `key-value flint <= 0.2.5` | less-or-equal |
| `key-value flint 0.2.0`    | bare = `>= 0.2.0` |

Parsing / matching is delegated to the standalone
[fsemver](https://github.com/VitaSound/fsemver) package — the very
same engine fmix uses, so the operator grammar can't drift between
tools.

If your installed flint doesn't satisfy the requirement, flint prints a
`[WARN]` line and **keeps running** — flint is a linter, not a gate. A
future major bump may make this strict, but for now you'll see e.g.:

```
[WARN] This project requires flint ~> 0.3, but you have 0.2.0
       Continuing anyway — flint won't block your lint.
```

The legacy form `key-list dependencies flint <ver>` is detected and
surfaced as a WARN with the same migration target.

## Tests

```bash
bash tests/flint_integration_test.sh
```

Fixtures live under `tests/fixtures/with_dupes/` and `tests/fixtures/no_dupes/`.

## License

[COPL](LICENSE) (Communist Public License). Use freely; share alike.
