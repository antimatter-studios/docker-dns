FROM alpine:latest

MAINTAINER Chris Thomas <chris.alex.thomas@gmail.com>

RUN apk --no-cache add supervisor dnsmasq

ADD supervisor.conf /etc/supervisord.conf

EXPOSE 53 53/udp

ENTRYPOINT ["supervisord","--configuration","/etc/supervisord.conf"]