#!/bin/bash 

#docker exec postgres_master_cont /bin/sh -c "createuser --replication -P rep_user -U version_user"
Для postgres 15

1) на мастере правим postresql.conf так:

	max_wal_senders = 10            

	wal_keep_size = 10          

	wal_level = logical                     

	wal_log_hints = on 

2) на мастере правим pg_hba.conf так, добавив строчку:

	host    version_db     rep_user     10.18.13.3/16			trust

3) на слейве правим postresql.conf так:

	listen_addresses = "*"
	# по идее надо бы сменить на ip мастера, но ругается

4) в обоих сервисах для применения bind в компоус первый запуск контейнеров, если все делается с нуля закомментить, потом раскомментить и запустить снова
5) на слейве заводим ту же бд, что и на мастере. Можно лишь структуру - без данных


6) лучше ребутуть оба сервиса

7) на мастере:

psql -U version_user version_db

create publication db_pub for all tables;

8) на слейве:

psql -U version_user version_db

create subscription db_sub connection 'host=10.18.13.2 dbname=version_db user=version_user password=version_password' publication db_pub;

-----------------

Практическое руководство

1)Убедиться что папка data удалена у обоих сервисов
2)Удалить контейнеры
3)Закомментить байнды в компосах
4)Запустить оба сервиса
5)Остановить оба сервиса
6)Раскомментить байнды
7)Запустить оба сервиса
8)Запустить changedb скрипт с раскомменченными строками публикации и подписки (все остальное должно быть закомменчено)
