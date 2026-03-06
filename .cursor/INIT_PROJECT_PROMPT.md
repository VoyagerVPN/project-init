# Промпт инициализации проекта

**Использование:**
1. Открой этот файл в **мастер-проекте** (videomax-new).
2. Скопируй блок от `---BEGIN---` до `---END---`, вставь в чат **нового** проекта.
3. Скрипты: после init скопируй `scripts/backup.ps1` из мастер-проекта, либо `.cursor/templates/backup.ps1` → `scripts/backup.ps1` нового проекта.
4. `.brain/` не трогай — Brain MCP настраивается отдельно.

---

---BEGIN---

Инициализируй проект: создай структуру правил и конфигов. `.brain/` не создавай и не изменяй.

Создай следующие файлы:

**1. `.cursor/rules/project.mdc`**
```markdown
---
description: Структура проекта, пути, интеграции, карта команд и правил
alwaysApply: true
---

# Project Setup

Единое правило проекта. Детали Todoist/журналы — @tracker, логирование ошибок — @error-journal.

## Структура проекта
(корень)/.brain/, .tracker/, .cursor/rules/, .cursor/commands/, scripts/, backup.config.json

## Ключевые пути
.tracker/config.json | .tracker/journals/YYYY-MM-DD.md | .tracker/errors.md | .brain/config.json (не менять) | backup.config.json

## Карта команд
что на сегодня, план, таски → @tracker
задача: [название] → @tracker
давай [задачу] → @tracker
/report, отчёт, журнал на сегодня, что скинуть ПМу → @tracker
/journal, /журнал, /прогресс → добавить в журнал дня
backup, бэкап → scripts/backup.ps1
добавь в errors.md → @error-journal

## Backup
Триггеры: backup, бэкап, архивируй. Выполнить scripts\backup.ps1, вывести отчёт.

## Настройка
"настрой таск-трекинг" → .tracker/, find-projects → config.json
```

**2. `.cursor/rules/tracker.mdc`**
```markdown
---
description: Todoist, журналы по дням, отчёты, комментарии к задачам
alwaysApply: false
---

# Progress Journal & Todoist

projectId из .tracker/config.json

Команды: что на сегодня, задача: [название], давай [задачу], /report (отчёт), /journal (добавить в журнал), что нового, все задачи.

Журнал: .tracker/journal.md — один файл, вся история по дням (## YYYY-MM-DD). Шаблон и категории с иконками: .tracker/journals/template.md.
При записи — /journal (в секцию today). Отчёты для ПМа — /report (генерируются из journal.md, чуть подробнее). После отчёта (если ≥10:00) — добавить секцию на завтра.
Связь с errors.md: при закрытии бага — журнал дня, errors.md, Todoist комментарий.

ЗАПРЕЩЕНО: complete-tasks, add-tasks без запроса, дублировать комментарий.
```

**3. `.cursor/rules/error-journal.mdc`**
```markdown
---
description: Логирование ошибок в .tracker/errors.md, реестр багов
alwaysApply: false
---

# Error Journal

Триггеры: добавь в errors.md, залогируй ошибку.
Когда: баг не исправлен, архитектурная проблема, непонятное поведение, явный запрос.

Формат: ## ГГГГ-ММ-ДД ЧЧ:ММ — [Название] | Timestamp | Воспроизведение | Краткий анализ | Гипотезы | Требования для решения | Исправление
Правила: timestamp обязателен, не дублировать, исправление дописывать.
```

**4. `.tracker/config.json`**
```json
{
  "todoist": {
    "projectId": "ЗАПОЛНИТЬ",
    "projectName": "ЗАПОЛНИТЬ"
  }
}
```

**5. `.tracker/journal.md`** — общий журнал (вся история по дням):
```markdown
# Журнал (общая история)

## YYYY-MM-DD

### [🚀 Фича] Название
**Задача:** ...
**Решение:** ...
**Файлы:** ...
```

**6. `.tracker/journals/template.md`** — скопировать из мастер-проекта (шаблон + категории с иконками: 🚀 Фича, 🐛 Багфикс, 🎨 UI, 🔧 Рефакторинг, 📦 Инфра, 📝 Документ).

**7. `.tracker/errors.md`**
```markdown
# Error Journal


```

**8. `backup.config.json`**
```json
{
  "exclude": [".brain", ".cursor", ".temp", ".tracker", "logs"]
}
```

**9. `.cursor/commands/backup.md`**
```markdown
# Backup
Запусти scripts/backup.ps1 из корня, проверь exit code, выведи отчёт (статус, архиватор, путь, размер).
Триггеры: backup, бэкап, архивируй.
```

**10. `scripts/`** — создай папку. Файл backup.ps1: если в проекте есть @.cursor/templates/backup.ps1 — скопируй его в scripts/backup.ps1. Иначе создай заглушку: «Скопируй scripts/backup.ps1 из мастер-проекта (videomax-new) или из .cursor/templates/backup.ps1».

После создания спроси: «Привязать Todoist? Напиши „настрой таск-трекинг“. Скрипт backup: скопируй из мастер-проекта scripts/backup.ps1 в scripts/ этого проекта. Журнал: .tracker/journal.md — вся история. Отчёты для ПМа: /report — генерируются из журнала.»

---END---
