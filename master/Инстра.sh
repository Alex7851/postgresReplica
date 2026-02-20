#!/bin/bash 

#docker exec postgres_master_cont /bin/sh -c "createuser --replication -P rep_user -U version_user"
Для postgres 15

1) на мастере правим postresql.conf так:
	listen_addresses = '*' # только для докера, иначе не слушает ip
	wal_level = replica
	max_wal_senders = 2  # количество планируемых слейвов
	max_replication_slots = 2 # максимальное число слотов репликации
	hot_standby = on # определяет, можно или нет подключаться к postgresql для выполнения запросов в процессе восстановления
	hot_standby_feedback = on # определяет, будет или нет сервер slave сообщать мастеру о запросах, которые он выполняет.

2) на мастере правим pg_hba.conf так, добавив строчки:

host    replication     rep_user     10.18.13.3/16               trust
host    replication     rep_user     10.18.13.2/16               trust
host    replication     rep_user     127.0.0.1/16                trust


3) на слейве правим postresql.conf так:

	listen_addresses = "*"
	# по идее надо бы сменить на ip мастера, но ругается

4) в сервисе мастера для применения bind в компоус первый запуск контейнера, если все делается с нуля закомментить, потом раскомментить и запустить снова

5) запускаем слейв с параметром в компосе restart: "unless-stopped"


6) на мастере:

psql -U version_user version_db

сreate user rep_user replication login encrypted password '123'; # пароль по факту не роляет т.к. выше стоит "trust", в боевом режиме можно попробовать убрать trust на md5 или sha... но запускать реплику не через скрипт ибо по идее нужно будет ввести пароль

7) на слейве:

rm -rf /var/lib/postgresql/data/*
pg_basebackup  --host=10.18.13.2 --username=rep_user -Fp -Xs -P -R -D /var/lib/postgresql/data


-----------------

Практическое руководство

1)Убедиться что папка data удалена у обоих сервисов
2)Удалить контейнеры
3)Закомментить байнд в компосе мастера
4)Запустить мастер
5)Запустить changedb скрипт с раскомменченной строкой создания пользователя(мастер)
6)Запустить слейв


Скрипт создания таблицы для проверки репликации:

-----------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY, -- Автоинкрементный уникальный ID, первичный ключ.
                                        -- Альтернатива для PG10+: id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username        VARCHAR(50) UNIQUE NOT NULL, -- Имя пользователя, уникальное и обязательное.
    email           VARCHAR(255) UNIQUE NOT NULL, -- Email, уникальный и обязательный.
    password_hash   VARCHAR(255) NOT NULL, -- Хеш пароля (никогда не храните пароли в открытом виде!).
    is_active       BOOLEAN DEFAULT TRUE, -- Флаг активности пользователя.
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, -- Дата и время создания записи, с учетом временной зоны.
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP -- Дата и время последнего обновления.
);

-- Добавление комментария к таблице (не обязательно, но хорошая практика)
COMMENT ON TABLE users IS 'Таблица для хранения информации о пользователях системы';
COMMENT ON COLUMN users.username IS 'Уникальное имя пользователя для входа';
COMMENT ON COLUMN users.email IS 'Уникальный адрес электронной почты пользователя';

-- Опционально: Создание функции и триггера для автоматического обновления updated_at
-- Это гарантирует, что поле updated_at будет обновляться при каждом изменении строки.
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Пример вставки данных (для демонстрации)
INSERT INTO users (username, email, password_hash) VALUES
('john_doe', 'john.doe@example.com', 'some_hashed_password_1'),
('jane_smith', 'jane.smith@example.com', 'some_hashed_password_2');
-------------------------------------------------------------------------------------------------------------------