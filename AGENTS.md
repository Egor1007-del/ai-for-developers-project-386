# Руководство по репозиторию

- Приложение на Rails 8.1 / Ruby 4.0.6 использует SQLite, Slim, Hotwire и importmap. README описывает задуманный сценарий бронирования; сейчас корневой маршрут ведёт только на `home#index`, а `/up` проверяет работоспособность Rails.
- Версии Ruby, Node и Yarn закреплены в `mise.toml`. Выполните `mise install`, затем `bin/setup --skip-server`: команда установит гемы и зависимости Yarn с фиксированным lockfile и подготовит базу данных.
- `bin/dev` запускает Rails и отслеживание изменений CSS через Foreman (если Foreman отсутствует, он будет установлен). Редактируйте `app/assets/stylesheets/application.bootstrap.scss`; `yarn build:css` генерирует игнорируемый файл `app/assets/builds/application.css`. JavaScript использует importmap без сборщика.
- Запускайте Minitest командой `bin/rails test`, отдельный тест — `bin/rails test test/integration/smoke_test.rb:4`. Системные тесты запускаются отдельно: `bin/rails test:system`.
- `bin/rubocop` проверяет стиль Ruby, а `bin/ci` выполняет последовательность CI: подготовку, RuboCop, аудит гемов и importmap, Brakeman, тесты Rails и затем `RAILS_ENV=test bin/rails db:seed:replant`. Последний шаг сбрасывает тестовую базу данных; системные тесты в эту последовательность не входят.
- Не редактируйте и не удаляйте `.github/workflows/hexlet-check.yml`: файл генерируется для внешних проверок Хекслета.
