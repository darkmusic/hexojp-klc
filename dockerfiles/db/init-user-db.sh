#!/bin/bash

# Tablespace for app
mkdir /var/lib/postgresql/hexojp

# Tablespace for initial db import
# Note: may need to adjust this if needed depending on the version of postgres.
# This uses a wildcard though, so it should be fine for now.
mkdir -p /var/lib/postgresql/data/pg_tblspc/*/PG_16_202307071/16384

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  create tablespace hexojp location '/var/lib/postgresql/hexojp';
  grant create on tablespace hexojp to hexojpadmin;
  alter role $POSTGRES_USER set search_path to public;
EOSQL
