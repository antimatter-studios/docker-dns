FROM alpine:latest

LABEL MAINTAINER="Chris Thomas <chris.alex.thomas@gmail.com>"

RUN apk --no-cache add supervisor dnsmasq bind-tools

ADD ./supervisor.conf /etc/supervisord.conf
ADD ./dnsmasq.conf /etc/dnsmasq.conf

EXPOSE 53 53/udp

ENTRYPOINT ["supervisord","--configuration","/etc/supervisord.conf"]