# Backup

Запусти архивацию проекта и выдай отчёт.

## Шаги

0. **Проверить скрипт:**
   ```powershell
   Test-Path ".\scripts\backup.ps1"
   ```
   Если `False` → "Скрипт `scripts/backup.ps1` не найден. Скопируй из мастер-проекта или `.cursor/templates/backup.ps1`." → СТОП.

1. Определи корень проекта (workspace path).
2. Выполни скрипт:
   ```powershell
   cd "<workspace>"; powershell -ExecutionPolicy Bypass -File ".\scripts\backup.ps1"
   ```
3. Дождись завершения и проверь exit code.
4. Выведи отчёт:
   - Статус (УСПЕХ / ОШИБКА)
   - Архиватор
   - Путь к архиву и размер
   - Предупреждения (если есть)

## Пример отчёта

```
📦 Backup отчёт

Статус: УСПЕХ
Архиватор: WinRAR (макс. сжатие, тома 998 МБ)
Архив: videomax-new-2026-03-06-21-45.rar
Размер: 45.2 МБ
```

При ошибке (exit code ≠ 0): покажи вывод скрипта и предложи проверить WinRAR/7-Zip или запустить с `-SkipRun` для диагностики.
