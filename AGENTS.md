# Руководство по репозиторию

## Архитектура

- **Стек:** Ruby 4.0.6, Rails 8.1.4.1, SQLite, Slim, Bootstrap 5, Hotwire (Turbo и Stimulus), esbuild.
- **Архитектура:** Rails-монолит с серверной генерацией HTML, без отдельного frontend-приложения.
- **Текущее состояние:** `home#index` — главная страница; `/up` — проверка работоспособности. Функциональность бронирования пока отсутствует.

## Окружение и команды

Версии Ruby, Node.js и Yarn зафиксированы в `mise.toml`. Для Ruby-команд использовать окружение mise, не смешивая пути gems RVM и mise.

```bash
mise install
mise exec -- bin/setup --skip-server
mise run dev
mise exec -- bin/rails test
mise exec -- bin/rails test test/integration/smoke_test.rb
mise exec -- bin/rails test:system
mise exec -- bin/rubocop
mise run check
```

- `mise run dev` используется, если задача определена в `mise.toml`; иначе — `mise exec -- bin/dev`.
- `mise run check` запускает `bin/ci`.

## Соглашения

- JavaScript и TypeScript собираются через esbuild (jsbundling-rails); контроллеры Stimulus регистрируются в `app/javascript/controllers/index.js`.
- Стили Bootstrap редактируются в `app/assets/stylesheets/application.bootstrap.scss`; CSS собирается через Yarn.
- Коммиты оформлять по **Conventional Commits**: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`. Сообщения должны отражать фактические изменения.
- Запускать тесты для измененной функциональности. Перед завершением значимого этапа выполнять `mise run check`.
- **Не изменять и не удалять** `.github/workflows/hexlet-check.yml` — файл предназначен для внешних проверок Хекслета.

## CI

- `mise run check` запускает `bin/ci`: подготовку окружения, RuboCop, проверку типов TypeScript, аудит gems, Brakeman, Rails-тесты и проверку seeds.
- Системные тесты запускаются отдельно.
- GitHub Actions должен использовать ту же команду `mise run check`.

## Agent skills

### Issue tracker

Задачи ведутся в GitHub Issues репозитория. См. `docs/agents/issue-tracker.md`.

### Triage labels

Используются стандартные метки triage. См. `docs/agents/triage-labels.md`.

### Domain docs

Проект использует единый доменный контекст. См. `docs/agents/domain.md`.
