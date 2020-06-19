#!/usr/bin/env bash

# pgpassfile makes it easy and safe to login
echo "${HOST}:${PORT}:${DB}:${POSTGRES_USER}:${POSTGRES_PASSWORD}" > pgpassfile
chmod 600 pgpassfile

# execute query
export PGPASSFILE='pgpassfile'
psql "${URL}" -U ${POSTGRES_USER} -t -c "INSERT INTO referencedata.rights (id, description, name, type) VALUES('5920d0eb-c2df-411f-9d16-bf1e9b745bd9', NULL, 'PCMT_MANAGEMENT', 'GENERAL_ADMIN') ON CONFLICT DO NOTHING;"
