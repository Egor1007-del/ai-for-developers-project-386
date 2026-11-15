# Контракт API

`main.tsp` — источник контракта пяти операций. После изменения контракта выполните
`mise exec -- yarn generate:api`: команда обновляет `api/openapi.yaml` и SDK в
`app/javascript/generated`. Проверка TypeScript выполняется командой
`mise exec -- yarn typecheck`. Генерация также запускается в `mise run check`.

Сейчас сервер реализует только `GET /api/event_types`; остальные операции
описаны для следующих задач спецификации.
