# 🚀 Backup та Restore

## Прості команди

### Створити backup
```bash
make backup
```
Створює backup обох баз даних в папку `backups/`.

### Відновити з backup
```bash
make restore \
  POSTGRES=backups/postgres_2025-11-12_14-30-00.tar.gz \
  REDIS=backups/redis_2025-11-12_14-30-00.tar.gz
```

## Як це працює

Використовуємо **volume snapshots** - найшвидший метод:
- ⚡ **Backup: 1-2 секунди**
- ⚡ **Restore: 3-5 секунд**
- 📦 Повна копія всіх даних
- ✅ 100% точність відновлення

## Структура backup

```
backups/
├── postgres_2025-11-12_14-30-00.tar.gz  # PostgreSQL backup
└── redis_2025-11-12_14-30-00.tar.gz     # Redis backup
```

Формат назви: `{database}_{YYYY-MM-DD}_{HH-MM-SS}.tar.gz`

## Щоденна робота

### Ранок - backup перед роботою:
```bash
make backup
```

### Якщо щось пішло не так - відновити:
```bash
make restore \
  POSTGRES=backups/postgres_[TAB для автозавершення] \
  REDIS=backups/redis_[TAB для автозавершення]
```

### Повний reset (видалити все):
```bash
docker-compose down -v
docker-compose up -d
```

## Автоматизація

### Щоденний backup через cron:
```bash
# Додати в crontab:
0 3 * * * cd /path/to/docker && make backup

# Видалити старі backup (залишити 7 днів):
0 4 * * * find /path/to/docker/backups -name "*.tar.gz" -mtime +7 -delete
```

## Корисні команди

```bash
# Подивитись всі backup
ls -lh backups/

# Останні 2 backup
ls -lht backups/ | head -3

# Розмір backup
du -sh backups/

# Перевірити вміст backup
tar -tzf backups/postgres_2025-11-12_14-30-00.tar.gz | head
```

## Cloud backup (опціонально)

### AWS S3:
```bash
# Upload
aws s3 sync backups/ s3://your-bucket/db-backups/

# Download
aws s3 sync s3://your-bucket/db-backups/ backups/
```

### Rsync на інший сервер:
```bash
rsync -avz backups/ user@backup-server:/path/to/backups/
```

## ⚠️ Важливо

1. **Тестуйте restore** - backup без перевірки = немає backup
2. **Автоматизуйте** - не покладайтесь на пам'ять
3. **Зберігайте офсайт** - копіюйте важливі backup в cloud

## Швидка довідка

| Команда | Час | Опис |
|---------|-----|------|
| `make backup` | ~2 сек | Створити backup |
| `make restore POSTGRES=... REDIS=...` | ~5 сек | Відновити з backup |
| `ls -lh backups/` | миттєво | Показати всі backup |
| `docker-compose down -v` | миттєво | Видалити всі дані |