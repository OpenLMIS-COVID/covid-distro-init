FROM alpine:3.10

COPY run.sh /run.sh
COPY add_pcmt_right.sh /add_pcmt_right.sh

RUN apk update \
  && apk add --no-cache bash \
  && apk add postgresql-client \
  && apk add postgresql \
  && apk add curl

RUN chmod +x run.sh

EXPOSE 8080
CMD ["/run.sh"]