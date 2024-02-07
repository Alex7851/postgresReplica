#!/bin/bash 
docker exec postgres_master_cont /bin/sh -c "psql -At -U version_user version_db -c \"create user rep_user replication login encrypted password '123';\""
sleep 3
docker exec postgres_slave_cont /bin/sh -c "rm -rf /var/lib/postgresql/data/*; pg_basebackup  --host=10.18.13.2 --username=rep_user -Fp -Xs -P -R -D /var/lib/postgresql/data"


# docker exec postgres_master_cont /bin/sh -c "psql -At -U version_user version_db -c \"INSERT INTO versions (minor, major, build, released) VALUES (3, 2, 80, '2024-02-04');\""
#docker exec postgres_master_cont /bin/sh -c "psql -At -U version_user version_db -c 'DELETE FROM versions WHERE build=12;'"
#docker exec postgres_slave_cont /bin/sh -c "psql -At -U version_user version_db -c 'DELETE FROM versions WHERE build=149;'"
# for (( i = 0; i < 100000; i++ )); do
	
# 	chars=abcd1234ABCD
# 	for i in {1..200} ; do
# 	    string="'"$(echo -n "${chars:RANDOM%${#chars}:200}")"'"
# 	done
# docker exec postgres_master_cont /bin/sh -c "psql -At -U version_user version_db -c \"INSERT INTO versions_description (version_id, descrption) VALUES (12, 'тест');\""

# done

# do $$
# begin
#    for cnt in 1..1000000 loop
#     INSERT INTO versions_description (version_id, descrption) VALUES (11, 'brrtbrtbrtbrtbrtbnnhrfngfngfngndtnnyrthdfberfsbsrtbtsbsrhbtrhrthtsrrrrbnrsmrtytgnthgregfvwe4cvrwerfcwcedfwxdwexfexwfecfwefwefwefvwefwefwerfwevfewfewvfwevfewfewfewfeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeewdfergerghe');
#    end loop;
# end; $$


#docker exec -t postgres_dump_cont pg_dump  --dbname=postgresql://version_user:version_password@postgres_slave:5432/version_db > dump.sql 
