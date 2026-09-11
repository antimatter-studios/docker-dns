# A fixed release rather than :latest, so a build is reproducible and Dependabot
# proposes each upgrade as a pull request that CI tests first.
FROM alpine:3.24

LABEL MAINTAINER="Chris Thomas <chris.alex.thomas@gmail.com>"

RUN apk --no-cache add supervisor dnsmasq bind-tools

ADD ./supervisor.conf /etc/supervisord.conf
ADD ./dnsmasq.conf /etc/dnsmasq.conf

EXPOSE 53 53/udp

ENTRYPOINT ["supervisord","--configuration","/etc/supervisord.conf"]