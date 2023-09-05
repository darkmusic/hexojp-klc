FROM postgres:latest as base

COPY init-user-db.sh /docker-entrypoint-initdb.d/init-user-db.sh
COPY hexojp.tar.gz /docker-entrypoint-initdb.d/hexojp.tar.gz
