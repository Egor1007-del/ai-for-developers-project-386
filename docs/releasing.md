# Релизы

Release Please отслеживает Conventional Commits в `main` и создаёт или обновляет release PR с версией и `CHANGELOG.md`. После слияния этого PR создаются тег и GitHub Release. Первый релиз получит версию `v0.1.0`; в его changelog попадут подходящие коммиты из истории проекта.

Для работы workflow необходимо добавить в GitHub Actions секрет `RELEASE_PLEASE_TOKEN`: fine-grained PAT с доступом к этому репозиторию и правами Contents, Issues и Pull requests на чтение и запись. Используйте учётную запись, которой разрешено создавать pull request и релизы. Токен также позволяет запускать CI на release PR и другие workflow, реагирующие на релиз.

Если настройки репозитория ограничивают создание pull request через Actions, разрешите его в **Settings → Actions → General → Workflow permissions**. После добавления секрета запустите **Release Please** вручную через вкладку Actions либо дождитесь следующего push в `main`.

Коммиты `feat:` повышают minor-версию, `fix:` — patch-версию, а breaking changes — major-версию. Перед слиянием release PR проверьте предложенные версию и changelog.

Описания коммитов пишите на русском языке: release-please использует их в changelog без перевода.
