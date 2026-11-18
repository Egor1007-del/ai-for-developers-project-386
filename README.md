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

- Ruby 4.0.6, Rails 8.1.4.1, SQLite для разработки и PostgreSQL для production
- Slim, Bootstrap, Hotwire (Turbo и Stimulus), esbuild
- Node.js и Yarn для сборки JavaScript, TypeScript и стилей

## Установка

Необходим [mise](https://mise.jdx.dev/) для установки Ruby, Node.js, Yarn и hk.
Также установите утилиту командной строки `sqlite3`: Rails использует её для загрузки и сохранения SQL-схемы базы данных (например, `sudo apt install sqlite3` в Debian/Ubuntu).

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

### Production Docker

Для запуска нужна доступная PostgreSQL-база и секретный `SECRET_KEY_BASE` (например, результат `mise exec -- bin/rails secret`). Передайте строку подключения через `DATABASE_URL`. Если PostgreSQL работает в отдельном контейнере, подключите оба контейнера к одной Docker-сети (например, созданной командой `docker network create calendar-network`) и укажите имя контейнера PostgreSQL как хост в `DATABASE_URL`, а не `localhost`. В примере ниже PostgreSQL уже подключён к сети `calendar-network`.

```bash
docker build -t calendar-calls .
docker run --rm --network calendar-network -p 3000:3000 \
  -e DATABASE_URL="$DATABASE_URL" \
  -e SECRET_KEY_BASE="$SECRET_KEY_BASE" \
  -e PORT=3000 calendar-calls
```

Контейнер слушает `0.0.0.0` на порту `PORT` (по умолчанию 3000). При старте выполняются подготовка базы и seeds: недостающие начальные типы событий создаются по названию и длительности, существующие записи не перезаписываются. Данные сохраняются между перезапусками, пока сохраняется сама база PostgreSQL.

### Деплой и диагностика Render

`render.yaml` описывает бесплатный Docker-сервис в Oregon, использующий существующую базу `calendar-calls-db`. Blueprint подключает `DATABASE_URL` из базы и генерирует `SECRET_KEY_BASE`; секреты не нужно помещать в репозиторий. Сервис отслеживает только `main` и настроен на **After CI Checks Pass**.

Перед подтверждением Blueprint проверьте план в Render Dashboard: он должен создавать только веб-сервис и ссылаться на существующую базу. После публикации изменений убедитесь, что GitHub Actions действительно запустил и успешно завершил все три задания CI на коммите `main`: SQLite checks, PostgreSQL checks и Production Docker. Render также считает результаты `skipped` и `neutral` успешными; сам по себе включённый режим ожидания CI не гарантирует запуск каждого задания.

При сбое проверьте статус задания в GitHub Actions, затем Deploys, Events и логи сборки и приложения в Render Dashboard. Проверьте доступность PostgreSQL, настройки окружения и ответ `/up`. Не публикуйте значения переменных окружения и секреты в логах или отчётах.

На бесплатном тарифе Render позволяет откатиться к двум последним предыдущим деплоям. Откат приложения не откатывает базу данных: перед откатом проверьте совместимость предыдущего кода с текущей схемой и миграциями. После ручного деплоя конкретного коммита проверьте настройку автодеплоя: некоторые способы ручного деплоя отключают её.

### Render MCP в OpenCode

Проектный `opencode.json` подключает [hosted Render MCP](https://render.com/docs/mcp-server) по HTTPS с API-ключом из переменной окружения. Формат `mcp.render` совместим с OpenCode 1.19.6 и поддерживается текущей [схемой OpenCode](https://opencode.ai/config.json) как устаревший; в [документации V2](https://opencode.ai/docs/mcp-servers/) используется `mcp.servers.render`.

1. Если `RENDER_API_KEY` уже доступна процессу OpenCode, используйте существующую переменную. Иначе создайте API-ключ в [настройках аккаунта Render](https://dashboard.render.com/u/settings?add-api-key) и введите его в Bash без отображения и без сохранения в истории команд:

   ```bash
   read -r -s -p 'Render API key: ' RENDER_API_KEY
   export RENDER_API_KEY
   ```

   Не помещайте ключ в файлы проекта, сообщения или логи. Переменная должна быть доступна процессу OpenCode; по завершении работы можно выполнить `unset RENDER_API_KEY`.
2. Запустите OpenCode из этого же терминала в корне проекта. После изменения конфигурации или переменной полностью перезапустите OpenCode.
3. В том же терминале выполните `opencode mcp list`: у `render` должен быть статус `connected`. Этот статус сам по себе не подтверждает действительность ключа: проверьте доступ следующим шагом. При ошибке проверьте наличие переменной, доступность сети и права аккаунта Render, не выводя значение ключа.
4. В OpenCode попросите агента вызвать `list_workspaces`, подтвердите workspace `collective_blog` и попросите перечислить его сервисы (`list_services` с `workspaceId` выбранного workspace). Это проверка чтением без изменения ресурсов. Не публикуйте вывод, если он содержит конфиденциальные данные.

Render MCP предоставляет доступ к ресурсам аккаунта, включая операции изменения и деплоя. Используйте ключ только с доверенным клиентом и проверяйте запрашиваемые действия. OpenCode 1.19.6 при проверке чистой OAuth-авторизации сообщил, что сервер авторизации не поддерживает динамическую регистрацию клиента; поэтому здесь используется API-ключ.

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
