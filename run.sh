#!/usr/bin/env bash

set -e

# ensure some environment variables are set
: "${DATABASE_URL:?DATABASE_URL not set in environment}"
: "${POSTGRES_USER:?POSTGRES_USER not set in environment}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD not set in environment}"
: "${REQUISITION_TEMPLATE_FACILITY_TYPES:?REQUISITION_TEMPLATE_FACILITY_TYPES not set in environment}"
: "${REQUISITION_TEMPLATE_SBR_FACILITY_TYPES:?REQUISITION_TEMPLATE_SBR_FACILITY_TYPES not set in environment}"

# pull apart some of those pieces stuck together in DATABASE_URL

export URL=`echo ${DATABASE_URL} | sed -E 's/^jdbc\:(.+)/\1/'` # jdbc:<url>
: "${URL:?URL not parsed}"

export HOST=`echo ${DATABASE_URL} | sed -E 's/^.*\/{2}(.+):.*$/\1/'` # //<host>:
: "${HOST:?HOST not parsed}"

export PORT=`echo ${DATABASE_URL} | sed -E 's/^.*\:([0-9]+)\/.*$/\1/'` # :<port>/
: "${PORT:?Port not parsed}"

export DB=`echo ${DATABASE_URL} | sed -E 's/^.*\/(.+)\?*$/\1/'` # /<db>?
: "${DB:?DB not set}"

# wait for referencedata service
REFERENCEDATA_SERVICE_URL="${BASE_URL}/referencedata"

while true
do
  STATUS=$(curl -s -o /dev/null -w '%{http_code}' ${REFERENCEDATA_SERVICE_URL})
  if [ $STATUS -eq 200 ]; then
    echo "Referencedata is up"
    break
  else
    echo "Referencedata is unavailable - sleeping"
  fi
  sleep 5
done

# wait for requisition service
REQUISITION_SERVICE_URL="${BASE_URL}/requisition"

while true
do
  STATUS=$(curl -s -o /dev/null -w '%{http_code}' ${REQUISITION_SERVICE_URL})
  if [ $STATUS -eq 200 ]; then
    echo "Requisition is up"
    break
  else
    echo "Requisition is unavailable - sleeping"
  fi
  sleep 5
done

# wait for report service
REPORT_SERVICE_URL="${BASE_URL}/report"

while true
do
  STATUS=$(curl -s -o /dev/null -w '%{http_code}' ${REPORT_SERVICE_URL})
  if [ $STATUS -eq 200 ]; then
    echo "Report is up"
    break
  else
    echo "Report is unavailable - sleeping"
  fi
  sleep 5
done

chmod +x add_pcmt_right.sh add_requisition_templates.sh add_aggregate_equipment_status_report.sh

./add_pcmt_right.sh

./add_requisition_templates.sh "Requisition Template" "${REQUISITION_TEMPLATE_FACILITY_TYPES}" false requisition-templates/base_template_columns.json
./add_requisition_templates.sh "Requisition Template SBR" "${REQUISITION_TEMPLATE_SBR_FACILITY_TYPES}" true requisition-templates/sbr_template_columns.json

./add_aggregate_equipment_status_report.sh
