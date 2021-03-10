FROM docker.io/library/mariadb:10.7
COPY gobot-db.sql /docker-entrypoint-initdb.d/