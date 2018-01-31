FROM alpine:latest

MAINTAINER Chris Thomas <chris.alex.thomas@gmail.com>

RUN apk --no-cache add supervisor dnsmasq

ADD ./config/supervisor.conf /etc/supervisord.conf
ADD ./config/dnsmasq.conf /etc/dnsmasq.conf

EXPOSE 53 53/udp

ENTRYPOINT ["supervisord","--configuration","/etc/supervisord.conf"]