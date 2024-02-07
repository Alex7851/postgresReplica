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
3)Закомментить байнды в компосе мастера
4)Запустить оба сервиса
6)Раскомментить байнд у мастера
7)Перезапустить мастер
8)Запустить changedb скрипт с раскомменченными строками создания пользователя(мастер), задержки, удаления папки с бд и командой репликации (слейв)
9)Дождаться перезапуска слейва после кода ноль