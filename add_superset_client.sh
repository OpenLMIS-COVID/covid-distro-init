#!/usr/bin/env bash

set -e

# ensure some environment variables are set
: "${DATABASE_URL:?DATABASE_URL not set in environment}"
: "${POSTGRES_USER:?POSTGRES_USER not set in environment}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD not set in environment}"
: "${AUTH_SUPERSET_CLIENT_USER:?AUTH_SUPERSET_CLIENT_USER not set in environment}"
: "${AUTH_SUPERSET_CLIENT_PASSWORD:?AUTH_SUPERSET_CLIENT_PASSWORD not set in environment}"
: "${SUPERSET_URL:?SUPERSET_URL not set in environment}"
: "${BASE_URL:?BASE_URL not set in environment}"

# pull apart some of those pieces stuck together in DATABASE_URL

URL=`echo ${DATABASE_URL} | sed -E 's/^jdbc\:(.+)/\1/'` # jdbc:<url>
: "${URL:?URL not parsed}"

HOST=`echo ${DATABASE_URL} | sed -E 's/^.*\/{2}(.+):.*$/\1/'` # //<host>:
: "${HOST:?HOST not parsed}"

PORT=`echo ${DATABASE_URL} | sed -E 's/^.*\:([0-9]+)\/.*$/\1/'` # :<port>/
: "${PORT:?Port not parsed}"

DB=`echo ${DATABASE_URL} | sed -E 's/^.*\/(.+)\?*$/\1/'` # /<db>?
: "${DB:?DB not set}"

SUPERSET_REDIRECT_URI=`echo ${SUPERSET_URL}'/oauth-authorized/openlmis'`

AUTH_URL=`echo ${BASE_URL}/auth`

# wait for auth service
while true
do
  STATUS=$(curl -s -o /dev/null -w '%{http_code}' ${AUTH_URL})
  if [ $STATUS -eq 200 ]; then
    echo "Auth is up"
    break
  else
    echo "Auth is unavailable - sleeping"
  fi
  sleep 5
done

# pgpassfile makes it easy and safe to login
echo "${HOST}:${PORT}:${DB}:${POSTGRES_USER}:${POSTGRES_PASSWORD}" > pgpassfile
chmod 600 pgpassfile

# execute query
export PGPASSFILE='pgpassfile'
psql "${URL}" -U ${POSTGRES_USER} -t -c "INSERT INTO auth.oauth_client_details (clientid, authorities, authorizedgranttypes, clientsecret, redirecturi, resourceids, scope) VALUES('${AUTH_SUPERSET_CLIENT_USER}', 'TRUSTED_CLIENT', 'authorization_code', '${AUTH_SUPERSET_CLIENT_PASSWORD}', '${SUPERSET_REDIRECT_URI}', 'hapifhir,notification,pcmtintegration,cce,auth,requisition,referencedata,report,stockmanagement,fulfillment,reference-instance-ui', 'read,write') ON CONFLICT DO NOTHING;"
