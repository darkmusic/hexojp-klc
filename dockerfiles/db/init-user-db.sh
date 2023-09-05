#!/bin/bash
set -e

mkdir /var/lib/postgresql/hexojp
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  create tablespace hexojp location '/var/lib/postgresql/hexojp';
  grant create on tablespace hexojp to hexojpadmin;
  alter role $POSTGRES_USER set search_path to public;
EOSQL
