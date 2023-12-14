FROM docker.io/library/mariadb:10.7
COPY gobot-db.sql /docker-entrypoint-initdb.d/
# COPY delete-slack-messages.sql /docker-entrypoint-initdb.d/
# -- delete-slack-messages.sql looks like:
# DELETE FROM slack_messages;
