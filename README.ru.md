# flint

[English version](README.md)

Маленький линтер для Forth-исходников.

Сейчас flint умеет одну вещь — **искать дублирующиеся определения слов**
между файлами проекта и его зависимостей. Он сканирует все `*.4th` под
текущей директорией, собирает все именованные определения (`:`,
`variable`, `create`, `defer`, `value`, `marker`, `field`, …) и выводит
предупреждение для каждого имени, встретившегося больше чем в одном
файле.

flint **нарочно «тупой» в первой версии**:

- Условную компиляцию не понимает: `[IFDEF] / [IFUNDEF]` игнорируются,
  каждое `: foo …` в любой ветке учитывается.
- Не дедуплицирует версии зависимостей. Если в `forth-packages/` лежат
  и `ttester/1.1.0/`, и `ttester/1.2.0/` — все слова ttester прозвенят
  как дубликаты. Именно это и нужный сигнал: «у тебя в проекте лишняя
  копия зависимости».
- Никакой семантики Forth — мы не выполняем код, это просто разбор
  текста с пропуском комментариев и строк.

Вывод — **только warning'и**, exit-код всегда 0. flint — это подсказка,
а не блокирующая проверка. В CI можно ловить через
`grep '\[WARN\]'` и обрабатывать как захочется.

Часть [семейства инструментов VitaSound для
Forth](https://github.com/VitaSound):
[fmix](https://github.com/VitaSound/fmix) (сборка / пакетный менеджер /
тест-раннер), [ttester](https://github.com/VitaSound/ttester) (тестовая
утилита — upstream Hayes/Ertl + расширения VitaSound),
[fenum](https://github.com/VitaSound/fenum) (универсальные контейнеры,
flint использует их под список записей), flint.

## Установка

```bash
cd ~ && git clone git@github.com:VitaSound/flint.git
cd flint && fmix packages.get
```

В `~/.bashrc` (или `~/.zshrc`):

```bash
# Инструменты VitaSound для Forth
export PATH="$HOME/fmix/bin:$HOME/flint/bin:$PATH"
```

Перечитать конфиг и проверить:

```bash
source ~/.bashrc
flint version
```

flint требует Gforth ≥ 0.7.9 и пользуется системной утилитой `find` для
обхода файлов — и то, и другое есть «из коробки» на любом
Linux/macOS.

Если flint лежит не в `$HOME/flint`, экспортируйте `$FLINT_HOME`
перед вызовом.

## Использование

```bash
flint               # линтить текущую директорию (warnings + краткий итог)
flint lint <path>   # линтить другую директорию
flint version       # версия
flint help          # справка
```

Типичный вывод:

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

## Какие определения распознаются

```
:  variable 2variable fvariable
constant 2constant fconstant
value 2value fvalue
create defer marker
field field: cfield: nfield: ufield:
code synonym
```

Добавляются в `flint/scan.4th : flint.defining?`.

## Известные ограничения / возможные ложные срабатывания

| Ситуация | Как ведёт себя flint | Что делать |
|----------|----------------------|------------|
| Одна и та же зависимость в двух версиях в `forth-packages/` | Сообщит про каждое слово | Чистите старые: `rm -rf forth-packages/<name>/<old>` |
| Переопределение внутри `[IFUNDEF] foo … [THEN]` (намеренный полифилл) | Тоже сообщит | Зафиксируйте порядок загрузки или вынесите полифилл в отдельный файл, который грузится один раз |
| `:noname`-лямбды | Не учитываются (имени нет → конфликта нет) | — |
| `: ( name-shadowed-by-comment ) bar ;` (paren-комментарий в позиции имени) | Парсер пропускает комментарий, регистрирует `bar` | — |
| Слова в строковых литералах (`s" : not-a-defn"`) | Игнорируются корректно | — |

## Устройство

| Файл | Что внутри |
|------|------------|
| `bin/flint` | bash-лаунчер (восстановление TTY, передача env-переменных в gforth, расширение `fpath`) |
| `flint.4th` | точка входа: разбор аргументов, диспетчер команд |
| `flint/util.4th` | строковые и регистровые хелперы |
| `flint/scan.4th` | пофайловый сканер токенов с хуком `defer flint.on-defined-word` |
| `flint/collect.4th` | список записей поверх [fenum](https://github.com/VitaSound/fenum)'овского `ulist` (одна структура на пару `(file, word)`) |
| `flint/walk.4th` | `find -type f -name '*.4th'` → список путей |
| `flint/report.4th` | группирует записи по имени, печатает один WARN на реальный дубликат |

## Тесты

```bash
bash tests/flint_integration_test.sh
```

Фикстуры лежат в `tests/fixtures/with_dupes/` и `tests/fixtures/no_dupes/`.

## Лицензия

[COPL](LICENSE) — Communist Public License. Используйте свободно,
делитесь с другими.
