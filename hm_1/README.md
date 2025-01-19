To run everything just use docker-compose up.

### Creating primary instance
I took default PostgreSQL configuration files and placed them into config folder within postgres_1. Just heard it's a good practice to not get any surprises on production and it's just easier to set up replication in next steps.

I run `docker-compose up` for docker-compose.yml:
```bash 
version: '3.8'
services:
  db:
    image: postgres:15-alpine
    container_name: postgres_1
    restart: unless-stopped
    networks:
      - postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: bookingdb
      PGDATA: /data
    volumes: 
      - ./postgres_1/pgdata:/data
      - ./postgres_1/config:/config
      - ./postgres_1/archive:/mnt/server/archive
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    ports:
      - "5000:5432"
    command: -c 'config_file=/config/postgresql.conf'

networks:
  postgres:
    name: postgres
```

- I provided volumes to persist data and configs as well as mounted one for archiving

### Creating replication user
Via Docker desktop I opened bash of the container and created user with the command below:

`createuser -U postgres -P -c 5 --replication replicationUser`

### Enabling WAL, replication and archive
Extended postgresql.conf with the following lines:
```
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /mnt/server/archive/%f && cp %p /mnt/server/archive/%f'
max_wal_senders = 3
```

### Taking a base backup
I wanted to get pgdata folder within postgres_2 with replication and streaming capabilities so I created an instances:
```
docker run -it --rm `
--net postgres `
-v ${PWD}/postgres_2/pgdata:/data `
--entrypoint /bin/bash postgres:15-alpine
```
and run
`pg_basebackup -h postgres_1 -p 5432 -U replicationUser -D /data/ -Fp -Xs -R`
This way I contected to my replicationUser. Forgot to mention that before this I added line `host     replication     replicationUser         0.0.0.0/0        md5` to pg_hba.conf of my primary instance to allow that to happen.

### Starting standby instance
Because data volume for standby server has been already prepared from previous step I added replica server to docker-compose.yml file and rerun it.


### Bonus tasks
Script:
```sql
SELECT
    a.airport_code,
    
    (SELECT COUNT(*)
     FROM flights f
     WHERE f.departure_airport = a.airport_code
    ) AS departure_flights_num,

    (SELECT COUNT(*)
     FROM flights f
     JOIN ticket_flights tf ON tf.flight_id = f.flight_id
     WHERE f.departure_airport = a.airport_code
    ) AS departure_psngr_num,

    (SELECT COUNT(*)
     FROM flights f
     WHERE f.arrival_airport = a.airport_code
    ) AS arrival_flights_num,

    (SELECT COUNT(*)
     FROM flights f
     JOIN ticket_flights tf ON tf.flight_id = f.flight_id
     WHERE f.arrival_airport = a.airport_code
    ) AS arrival_psngr_num

FROM airports a
ORDER BY a.airport_code;
```
View:
```sql
CREATE OR REPLACE VIEW airport_passenger_traffic AS
SELECT
    a.airport_code,
    (SELECT COUNT(*)
     FROM flights f
     WHERE f.departure_airport = a.airport_code
    ) AS departure_flights_num,
    (SELECT COUNT(*)
     FROM flights f
     JOIN ticket_flights tf ON tf.flight_id = f.flight_id
     WHERE f.departure_airport = a.airport_code
    ) AS departure_psngr_num,
    (SELECT COUNT(*)
     FROM flights f
     WHERE f.arrival_airport = a.airport_code
    ) AS arrival_flights_num,
    (SELECT COUNT(*)
     FROM flights f
     JOIN ticket_flights tf ON tf.flight_id = f.flight_id
     WHERE f.arrival_airport = a.airport_code
    ) AS arrival_psngr_num
FROM airports a;
```

I populated db with sample data and run the `SELECT * FROM airport_passenger_traffic;`. Script and replication were working as expected.

