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

В `~/.bashrc` (или `~/.zshrc`) — по одной строке на каждый
инструмент, чтобы они оставались независимы (установить/удалить любой
из них можно отдельно от остальных):

```bash
export PATH="$HOME/flint/bin:$PATH"
```

(если рядом стоят соседние инструменты, добавляйте им отдельные строки
— например `export PATH="$HOME/fmix/bin:$PATH"`, `export PATH="$HOME/fcov/bin:$PATH"`)

Перечитать конфиг и проверить:

```bash
source ~/.bashrc
flint version
```

flint требует только Gforth ≥ 0.7.9 — никаких других зависимостей от
ОС. Обход каталогов сделан на родных словах Gforth (`open-dir`/
`read-dir`), поэтому flint переносится на любую систему с приличным
ANS Forth.

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
| `flint/walk.4th` | рекурсивный обход на родных словах Gforth (`open-dir` / `read-dir` / `close-dir`), без shell-out на `find` |
| `flint/report.4th` | группирует записи по имени, печатает один WARN на реальный дубликат |
| `flint/version-check.4th` | читает `key-value flint <req>` из `./package.4th` и печатает WARN (не блокирует), если установленный flint не подходит. Парсинг / матчинг делегированы [fsemver](https://github.com/VitaSound/fsemver) (общий движок с fmix). |

## Привязка версии flint (`key-value flint ~> X.Y`)

В `package.4th` проекта можно объявить минимально допустимую версию
flint в том же синтаксисе, что и для fmix:

```forth
forth-package
    key-value name myproj
    key-value version 0.1.0
    key-value main myproj.4th
    key-value flint ~> 0.2
end-forth-package
```

| Запись | Что означает |
|--------|--------------|
| `key-value flint ~> 0.2` | `>= 0.2.0` и `< 1.0.0` (MAJOR зафиксирован) |
| `key-value flint ~> 0.2.3` | `>= 0.2.3` и `< 0.3.0` (MAJOR+MINOR зафиксированы) |
| `key-value flint >= 0.2.0` | минимум, без верхней границы |
| `key-value flint == 0.2.0` | ровно эта версия |
| `key-value flint >  0.2.0` | строго больше |
| `key-value flint <  1.0.0` | строго меньше |
| `key-value flint <= 0.2.5` | меньше-или-равно |
| `key-value flint 0.2.0`    | голая версия = `>= 0.2.0` |

Парсинг / матчинг делегированы отдельной библиотеке
[fsemver](https://github.com/VitaSound/fsemver) — это тот же движок,
что и в fmix, поэтому грамматика операторов гарантированно не
разойдётся между инструментами.

Если установленный flint не подходит, печатается `[WARN]`, но линтер
**всё равно отрабатывает** — flint это подсказка, а не «ворота»
сборки. В будущей мажорной версии может стать строгой проверкой; пока
просто увидите что-то вроде:

```
[WARN] This project requires flint ~> 0.3, but you have 0.2.0
       Continuing anyway — flint won't block your lint.
```

Старый формат `key-list dependencies flint <ver>` тоже распознаётся и
выводится в виде WARN с подсказкой по миграции.

## Тесты

```bash
bash tests/flint_integration_test.sh
```

Фикстуры лежат в `tests/fixtures/with_dupes/` и `tests/fixtures/no_dupes/`.

## Публикация на theforth.net

[theforth.net](https://theforth.net/) — официальный реестр
Forth-пакетов. Туда полезно выложить flint, чтобы соседние проекты
могли прописать его как зависимость в своих `package.4th`.

Краткая инструкция (по [guidelines](https://theforth.net/guidelines)):

1. Создай аккаунт: <https://theforth.net/profile>.

2. Проверь `package.4th`. У flint он уже под guidelines — обязательные
   поля (`name`, `version` `MAJOR.MINOR.PATCH`, `license`, `main`)
   на месте, плюс `description`, `tags`, `dependencies`.

3. Собери архив. **Корневая папка в архиве должна точно совпадать с
   полем `name`** (`flint`), и `package.4th` лежит в её корне:

   ```bash
   cd ~                                            # на уровень выше flint/
   tar czf flint-0.1.1.tar.gz \
       --exclude='flint/.git' \
       --exclude='flint/forth-packages' \
       --exclude='flint/build' \
       flint
   ```

4. Залогинься на theforth.net, перейди в
   [Profile](https://theforth.net/profile) и загрузи архив через форму
   upload.

5. После публикации НЕ меняй `version` для уже выложенного слота —
   повышай его по SemVer:
   - **PATCH** — обратно-совместимый багфикс,
   - **MINOR** — обратно-совместимое добавление функциональности,
   - **MAJOR** — несовместимое изменение API.

## Лицензия

[COPL](LICENSE) — Communist Public License. Используйте свободно,
делитесь с другими.
