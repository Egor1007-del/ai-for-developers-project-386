# Календарь звонков


[![hexlet-check](https://github.com/Egor1007-del/ai-for-developers-project-386/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/Egor1007-del/ai-for-developers-project-386/actions)

Разработайте совместно с ИИ сервис для бронирования календаря

Учебный проект Хекслета: https://ru.hexlet.io/programs/ai-for-developers
Как это должно работать: https://files.hexlet.app/a/2ipc5m

## Сценарий бронирования

1. Владелец создаёт тип встречи, указав название, описание и длительность.
2. Гость без регистрации выбирает тип встречи и открывает календарь на ближайшие 14 дней.
3. Гость выбирает свободный слот, вводит имя и email и подтверждает запись.
4. Гость видит подтверждение встречи, а занятое время становится недоступным для других записей, включая встречи других типов.
5. Владелец видит новую встречу в списке предстоящих записей всех типов.

## Стек

- Ruby 4.0.6, Rails 8.1.4.1, SQLite
- Slim, Bootstrap, Hotwire (Turbo и Stimulus), esbuild
- Node.js и Yarn для сборки JavaScript, TypeScript и стилей

## Установка

Необходим [mise](https://mise.jdx.dev/) для установки Ruby, Node.js, Yarn и hk.

```bash
git clone https://github.com/Egor1007-del/ai-for-developers-project-386.git
cd ai-for-developers-project-386
mise install
mise run setup
```

## Использование

```bash
mise run dev
```

Откройте http://localhost:3000. Пока доступен только каркас приложения.

Проверка состояния приложения: http://localhost:3000/up.

### Фоновый запуск через mise daemons

Альтернативный способ запуска сервера и сборки JavaScript и стилей — фоновые процессы под управлением pitchfork. Поддержка daemons в mise является экспериментальной; она включена в конфигурации проекта. При первом запуске mise установит закреплённую версию pitchfork, если она ещё не установлена.

```bash
mise daemons start   # запустить web, js и css
mise daemons status  # проверить состояние
mise daemons logs    # посмотреть вывод процессов
mise daemons stop    # остановить процессы
```

Оба способа запуска используют порт 3000, поэтому перед переключением остановите работающий сервер.

## Проверки

Версии Ruby, Node.js и Yarn и команды для [mise](https://mise.jdx.dev/) указаны в `mise.toml`. После установки mise выполните `mise install`, затем:

```bash
mise run setup    # зависимости и база данных
mise run dev      # сервер и сборка JavaScript и стилей
mise run test     # Minitest
mise run lint     # RuboCop
mise run security # Brakeman
mise run check    # все проверки через bin/ci
```

Без mise общую проверку можно запустить командой `bin/ci` после установки зависимостей. Она же выполняется в GitHub Actions при каждом push и pull request.

JavaScript собирается командой `mise exec -- yarn build`, а TypeScript проверяется командой `mise exec -- yarn typecheck`. Новые Stimulus-контроллеры нужно импортировать и регистрировать в `app/javascript/controllers/index.js`. Rails автоматически собирает ассеты при запуске тестов и `assets:precompile`.

При `mise run setup` устанавливаются Git-хуки hk: перед коммитом запускается RuboCop, а сообщение проверяется на соответствие Conventional Commits (например, `feat: добавить календарь`). Для повторной установки хуков выполните `mise exec -- hk install --mise`.

---

<details>
<summary>Автоматические тесты Хекслета</summary>

Тесты запускаются на каждый коммит. За запуск отвечает файл `.github/workflows/hexlet-check.yml` — не удаляйте и не переименовывайте ни его, ни репозиторий.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.
