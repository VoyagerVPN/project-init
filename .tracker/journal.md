# Журнал (общая история)

Все записи по дням. Отчёты для ПМа генерируются из этого файла.

---

## 2026-03-06

### [🐛 Багфикс] parseParamValueToNumber, driverParamConfigManager, handleReset
**Задача:** Исправление нерешённых ошибок (docs/ERRORS.md).
**Решение:** parseParamValue — whitelist форматов в metrics.ts; config — один раз в enrichParametersFromConfig; handleReset — очищаются только пороги.
**Файлы:** `agent/.../metrics.ts`, `DriverSettingsTab.tsx`

### [🎨 UI] Стейт комментария (активен/не активен)
**Задача:** Более понятные комментарии к устройству.
**Решение:** Иконка активна (зелёная) / не активна (серая). Точку-индикатор убрали.
**Файлы:** `agent/.../MainTab.tsx`

### [🚀 Фича] ChildState / effectiveState (overspill статуса потоков)
**Задача:** Обозначение warning и alert у потоков.
**Решение:** childState: заголовок учитывает худший статус среди потоков. effectiveState = worstOf(cpuParam.state, worstThreadState).
**Файлы:** `monitor/.../MetricGroupCard.tsx`, `agent/.../MainTab.tsx`

### [🎨 UI] Фидбэк от кнопки Обновить
**Задача:** Фидбэк при нажатии «Обновить».
**Решение:** Иконка RefreshCw крутится, текст «Обновление…», минимум 400 мс.
**Файлы:** `monitor/.../useAgents.ts`, `MonitorPage.tsx`

### [🎨 UI] Отладка иконок (консистентность)
**Задача:** Консистентность иконок по категориям.
**Решение:** cooling→Fan, gpu→Gpu, power→Plug, system→Monitor. Логотип — Airplay.
**Файлы:** `shared/groupIcons.ts`, `MetricGroupCard.tsx`, `Header.tsx`, `AboutModal.tsx`, `MainTab.tsx`

### [🚀 Фича] Переключатель показателей в мониторе
**Задача:** Режимы «Подробно» / «Компактно».
**Решение:** Компакт — только карточки + badge, без показателей и деталей.
**Файлы:** `monitor/.../MonitorPage.tsx`, `MetricGroupCard.tsx`

### [📦 Инфра] Покрытие тестами (план)
**Задача:** Покрытие тестов до 50%.
**Решение:** Парсеры в тестируемые модули, unit-тесты. Agent: 194, Monitor: 53. Покрытие ~25–28%.
**Файлы:** `agent/tests/unit/*`, `monitor/.../*.test.ts`
