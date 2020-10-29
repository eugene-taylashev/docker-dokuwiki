FROM alpine:latest

RUN apk --update --no-cache add apache2 apache2-ssl ssmtp \
  php7-apache2 php7-session php7-openssl php7-json php7-xml php7-gd php7-ldap

#-- Redirect logs
RUN ln -sf /dev/stdout /var/log/apache2/access.log && ln -sf /dev/stderr /var/log/apache2/error.log

LABEL maintainer="Eugene Taylashev" \
  url="https://github.com/eugene-taylashev/docker-dokuwiki" \
  source="https://hub.docker.com/repository/docker/etaylashev/dokuwiki" \
  title="DokuWiki" \
  description="DokuWiki is a simple to use and highly versatile Open Source wiki software that doesn't require a database. This image could be used to run new or existing DokuWiki over HTTP or HTTPs with default or specific configuration"

#-- ports exposed
EXPOSE 80
EXPOSE 443

#-- default environment variables
ENV URL_CONF=none
ENV SKEY=none
ENV VERBOSE=0

COPY ./entrypoint.sh /usr/local/bin/

CMD ["entrypoint.sh"]
