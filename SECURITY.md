# 🔒 Налаштування безпеки для продакшену

## ⚠️ ВАЖЛИВО
Поточна конфігурація оптимізована для **локальної розробки**. Для продакшену потрібні додаткові налаштування безпеки.

## Redis Security

### Поточні налаштування (розробка):
```yaml
--protected-mode no     # Дозволяє підключення ззовні
--bind 0.0.0.0         # Слухає на всіх інтерфейсах
# Без пароля
```

### Для продакшену:

#### Варіант 1: З паролем
```yaml
command: >
  redis-server
  --requirepass ${REDIS_PASSWORD}
  --protected-mode yes
  --bind 0.0.0.0
  # інші налаштування...
```

В `.env`:
```bash
REDIS_PASSWORD=your_strong_password_here
```

Підключення з додатку:
```javascript
// Node.js приклад
const redis = require('redis');
const client = redis.createClient({
  host: 'localhost',
  port: 6379,
  password: process.env.REDIS_PASSWORD
});
```

#### Варіант 2: Тільки локальні підключення
```yaml
command: >
  redis-server
  --protected-mode yes
  --bind 127.0.0.1
  # інші налаштування...
```

#### Варіант 3: Docker network isolation
```yaml
services:
  redis:
    # ...
    ports:
      # Видалити ports секцію - Redis буде доступний тільки в Docker network
    networks:
      - internal

  app:
    # ...
    networks:
      - internal

networks:
  internal:
    internal: true  # Ізольована мережа
```

## PostgreSQL Security

### Поточні налаштування:
- SCRAM-SHA-256 автентифікація ✅
- Пароль в `.env` файлі ⚠️

### Для продакшену:

#### 1. Використовуйте Docker secrets:
```yaml
services:
  postgres:
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    secrets:
      - postgres_password

secrets:
  postgres_password:
    file: ./secrets/postgres_password.txt
```

#### 2. Обмежте підключення:
Створіть `pg_hba.conf`:
```
# TYPE  DATABASE    USER        ADDRESS         METHOD
local   all         all                         scram-sha-256
host    all         all         172.28.0.0/16   scram-sha-256
host    all         all         127.0.0.1/32    scram-sha-256
```

#### 3. SSL підключення:
```yaml
command: >
  postgres
  -c ssl=on
  -c ssl_cert_file=/var/lib/postgresql/server.crt
  -c ssl_key_file=/var/lib/postgresql/server.key
```

## Загальні рекомендації

### 1. Firewall правила
```bash
# Дозволити тільки з певних IP
iptables -A INPUT -p tcp --dport 5432 -s YOUR_APP_IP -j ACCEPT
iptables -A INPUT -p tcp --dport 6379 -s YOUR_APP_IP -j ACCEPT
iptables -A INPUT -p tcp --dport 5432 -j DROP
iptables -A INPUT -p tcp --dport 6379 -j DROP
```

### 2. Використовуйте .env правильно
```bash
# .env.production (не комітити!)
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
```

### 3. Регулярні оновлення
```bash
# Оновлення образів
docker-compose pull
docker-compose up -d

# Перевірка вразливостей
docker scout cves postgres:17-alpine
docker scout cves redis:7-alpine
```

### 4. Моніторинг та логування
```yaml
services:
  postgres:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    command: >
      postgres
      -c log_connections=on
      -c log_disconnections=on
      -c log_statement=all
```

### 5. Backup стратегія
```bash
# Автоматичні backup через cron
0 */6 * * * /path/to/docker/make backup-all
0 3 * * * /path/to/docker/make backup-volumes

# Зберігання backup в cloud
aws s3 sync backups/ s3://your-backup-bucket/
```

## Швидка міграція на продакшн

### 1. Створіть продакшн .env:
```bash
cp .env.example .env.production
# Відредагуйте з сильними паролями
```

### 2. Створіть docker-compose.prod.yml:
```yaml
services:
  postgres:
    ports: []  # Видалити зовнішні порти

  redis:
    ports: []  # Видалити зовнішні порти
    command: >
      redis-server
      --requirepass ${REDIS_PASSWORD}
      --protected-mode yes
      # інші налаштування...
```

### 3. Запуск:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Checklist для продакшену

- [ ] Встановлені сильні паролі
- [ ] Protected mode увімкнено для Redis
- [ ] Видалені зовнішні порти або обмежені firewall
- [ ] Налаштовано SSL для PostgreSQL
- [ ] Використовуються Docker secrets
- [ ] Налаштовано автоматичні backup
- [ ] Увімкнено логування
- [ ] Регулярні оновлення образів
- [ ] Моніторинг health checks
- [ ] Обмежено мережевий доступ

## Контакти для питань безпеки

При виявленні вразливостей або питань безпеки, створіть приватний issue в репозиторії.