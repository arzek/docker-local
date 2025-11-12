# Docker Compose Setup: PostgreSQL + Redis

Сучасна конфігурація Docker Compose з PostgreSQL 17 та Redis 7 з оптимізованими налаштуваннями та best practices.

## Особливості

### PostgreSQL
- PostgreSQL 17 Alpine (найлегша версія)
- Оптимізовані параметри продуктивності
- Налаштована статистика та моніторинг (pg_stat_statements)
- SCRAM-SHA-256 автентифікація
- Автоматичні health checks
- Логування важливих подій

### Redis
- Redis 7 Alpine
- AOF persistence для збереження даних
- RDB snapshots
- Налаштована політика видалення ключів (LRU)
- Працює без пароля (для простоти розробки)
- Protected mode вимкнено (для підключення з хосту)
- Health checks


## Швидкий старт

1. **Скопіюйте та налаштуйте .env файл:**
```bash
cp .env.example .env
# Відредагуйте .env та встановіть безпечні паролі
```

2. **Запустіть сервіси:**
```bash
docker-compose up -d
```

3. **Перевірте статус:**
```bash
docker-compose ps
docker-compose logs -f
```

## Підключення

### PostgreSQL
- Host: localhost
- Port: 5432 (або змінна POSTGRES_PORT)
- Database: postgres (або змінна POSTGRES_DB)
- Username: postgres (або змінна POSTGRES_USER)
- Password: postgres (встановлюється в .env)

Connection string:
```
postgresql://postgres:postgres@localhost:5432/postgres
```

### Redis
- Host: localhost
- Port: 6379 (або змінна REDIS_PORT)
- Password: не потрібен

Connection string:
```
redis://localhost:6379
```

## Управління

### Основні команди
```bash
# Запуск
docker-compose up -d

# Зупинка
docker-compose down

# Зупинка з видаленням даних
docker-compose down -v

# Перегляд логів
docker-compose logs -f postgres
docker-compose logs -f redis

# Виконання команд в контейнері
docker-compose exec postgres psql -U postgres -d postgres
docker-compose exec redis redis-cli

# Резервне копіювання PostgreSQL
docker-compose exec postgres pg_dump -U postgres postgres > backup.sql

# Резервне копіювання Redis
docker-compose exec redis redis-cli --rdb /data/dump.rdb
```

### Управління Docker Volumes
```bash
# Переглянути всі volumes
docker volume ls

# Інформація про volume
docker volume inspect postgres-data
docker volume inspect redis-data

# Видалити volumes (УВАГА: видалить всі дані!)
docker volume rm postgres-data redis-data

# Створити backup volume PostgreSQL
docker run --rm -v postgres-data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz -C /data .

# Відновити backup volume PostgreSQL
docker run --rm -v postgres-data:/data -v $(pwd):/backup alpine tar xzf /backup/postgres-backup.tar.gz -C /data
```

### Моніторинг health checks
```bash
# Перевірка статусу сервісів
docker-compose ps

# Детальна інформація про health check
docker inspect postgres_db --format='{{json .State.Health}}' | jq
docker inspect redis_cache --format='{{json .State.Health}}' | jq
```

## Оптимізація продуктивності

### PostgreSQL налаштування
Конфігурація оптимізована для:
- 2 CPU cores
- 2-4 GB RAM
- SSD диски

Основні параметри:
- `shared_buffers`: 256MB
- `effective_cache_size`: 768MB
- `max_connections`: 200
- WAL оптимізація для швидшого запису
- Увімкнено паралельні запити

### Redis налаштування
- Максимальна пам'ять: 256MB (налаштовується)
- Політика видалення: allkeys-lru
- AOF persistence з записом кожну секунду
- RDB snapshots для резервного копіювання

## Структура проекту
```
.
├── docker-compose.yml    # Основна конфігурація
├── .env                  # Локальні налаштування (не комітити!)
├── .env.example          # Приклад налаштувань
├── README.md             # Документація
├── Makefile              # Команди для управління
└── init-scripts/         # SQL скрипти для ініціалізації (опціонально)
```

**Docker Volumes:** Дані зберігаються в Docker named volumes (`postgres-data` та `redis-data`), які керуються Docker. Для перегляду volumes використовуйте `docker volume ls`.

## Безпека

### Рекомендації
1. **Завжди** змінюйте паролі за замовчуванням в .env файлі
2. Не комітьте .env файл в git (додайте до .gitignore)
3. Використовуйте складні паролі для PostgreSQL
4. **Redis** налаштовано без пароля для простоти розробки. Для продакшену додайте `--requirepass` в команду Redis
5. В продакшені обмежте доступ через firewall
6. Регулярно оновлюйте Docker образи

### .gitignore
```gitignore
.env
*.sql
*.rdb
*.aof
backups/
```

## Troubleshooting

### PostgreSQL не запускається
```bash
# Перевірте логи
docker-compose logs postgres

# Видаліть стару папку з даними
docker-compose down -v
docker-compose up -d
```

### Redis не приймає підключення
```bash
# Перевірте пароль в .env
# Перевірте health check
docker-compose exec redis redis-cli ping
```

### Проблеми з пам'яттю
```bash
# Перевірте використання пам'яті
docker stats

# Зменшіть параметри в docker-compose.yml:
# - shared_buffers для PostgreSQL
# - maxmemory для Redis
```

## Ліцензія
MIT