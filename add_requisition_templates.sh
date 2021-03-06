#!/usr/bin/env bash

# pgpassfile makes it easy and safe to login
echo "${HOST}:${PORT}:${DB}:${POSTGRES_USER}:${POSTGRES_PASSWORD}" > pgpassfile
chmod 600 pgpassfile

# assign template name from the arguments and wrap it with single quotes
export TEMPLATE_NAME=\'$1\'
# assign facility types from the arguments and remove the double quotes if exists
export FACILITY_TYPES=`echo $2 | tr -d '"'`
# simply assign the flag value from the arguments
export POPULATE_SOH_FROM_STOCK_CARDS=$3

# execute query
export PGPASSFILE='pgpassfile'
export REQUISITION_COLUMNS=`cat $4`

psql "${URL}" -U ${POSTGRES_USER} -t -c "

DO \$\$
DECLARE requisition_template_id uuid := uuid_generate_v4();
BEGIN

IF NOT EXISTS (SELECT * FROM pg_type WHERE typname = 'requisition_column_definition') THEN
CREATE TYPE requisition_column_definition AS
	(columntype TEXT, source INT4, displayorder INT4, definition TEXT, indicator VARCHAR, isdisplayed BOOL, label VARCHAR, name VARCHAR, tag VARCHAR, option VARCHAR);
END IF;

IF NOT EXISTS (SELECT * FROM requisition.requisition_templates WHERE name = ${TEMPLATE_NAME}) THEN
	INSERT INTO requisition.requisition_templates
		(id, createddate, numberofperiodstoaverage,	populatestockonhandfromstockcards, archived, name)
		VALUES(requisition_template_id, NOW(), 3, ${POPULATE_SOH_FROM_STOCK_CARDS}, FALSE, ${TEMPLATE_NAME});

	INSERT INTO requisition.columns_maps
		(requisitiontemplateid, requisitioncolumnid, definition, displayorder, indicator, isdisplayed, label, name, requisitioncolumnoptionid, source, key, tag)
		SELECT requisition_template_id, available_column.id, column_definition.definition, column_definition.displayorder, column_definition.indicator,
		column_definition.isdisplayed, column_definition.label, column_definition.name, option.id, column_definition.source, column_definition.name, column_definition.tag
			FROM json_populate_recordset(null::requisition_column_definition, '${REQUISITION_COLUMNS}') column_definition
			LEFT JOIN requisition.available_requisition_column_options option ON column_definition.option = option.optionname
			INNER JOIN requisition.available_requisition_columns available_column ON column_definition.name = available_column.name;
END IF;

INSERT INTO requisition.requisition_template_assignments
	(id, programid, facilitytypeid, templateid)
	SELECT uuid_generate_v4(), program.id, facility_type.id, template.id
		FROM referencedata.programs program
		CROSS JOIN referencedata.facility_types facility_type
		CROSS JOIN requisition.requisition_templates template
		WHERE facility_type.code = ANY(ARRAY${FACILITY_TYPES})
		AND template.name = ${TEMPLATE_NAME}
	ON CONFLICT DO NOTHING;

END \$\$
"
