FROM anapsix/alpine-java:8u202b08_jdk

COPY add_pcmt_right.sh /add_pcmt_right.sh

RUN chmod +x add_pcmt_right.sh \
  && apk update \
  && apk add postgresql-client \
  && apk add postgresql \
  $$ apk add curl

EXPOSE 8080
CMD ["/add_pcmt_right.sh"]