FROM alpine:3.10

COPY run.sh /run.sh
COPY add_pcmt_right.sh /add_pcmt_right.sh
COPY add_requisition_templates.sh /add_requisition_templates.sh
COPY requisition-templates/base_template_columns.json /requisition-templates/base_template_columns.json
COPY requisition-templates/sbr_template_columns.json /requisition-templates/sbr_template_columns.json
COPY add_aggregate_equipment_status_report.sh /add_aggregate_equipment_status_report.sh

RUN apk update \
  && apk add --no-cache bash \
  && apk add postgresql-client \
  && apk add postgresql \
  && apk add curl

RUN chmod +x run.sh

EXPOSE 8080
CMD ["/run.sh"]