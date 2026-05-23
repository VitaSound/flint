# flint

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
- No dependency-version dedup (if you have `forth-packages/ttester/1.1.0/`
  *and* `forth-packages/ttester/1.2.0/` in your tree, you'll see warnings
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

Add to your `~/.bashrc` (or `~/.zshrc`):

```bash
# VitaSound Forth tooling
export PATH="$HOME/fmix/bin:$HOME/flint/bin:$PATH"
```

Then `source ~/.bashrc` and verify:

```bash
flint version
```

flint requires Gforth ≥ 0.7.9 and shells out to `find` for file
discovery; both ship on every Linux/macOS box you're likely to use.

If you keep flint somewhere other than `$HOME/flint`, set
`$FLINT_HOME` before invoking `flint` (the launcher honours it).

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
    ./forth-packages/ttester/1.1.0/ttester.4th
    ./forth-packages/ttester/1.2.0/ttester.4th

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
| `flint/walk.4th` | `find -type f -name '*.4th'` → list of paths |
| `flint/report.4th` | group records by name, print one WARN per real duplicate |

## Tests

```bash
bash tests/flint_integration_test.sh
```

Fixtures live under `tests/fixtures/with_dupes/` and `tests/fixtures/no_dupes/`.

## License

[COPL](LICENSE) (Communist Public License). Use freely; share alike.
