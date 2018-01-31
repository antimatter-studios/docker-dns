# supervisord-dnsmasq
Supervisord controlled DNSMasq allowing updates for domains without modifying the config

This project was born out of a need to run a dnsmasq docker container to resolve hostnames on my docker containers without wanting to constantly edit the system files to make the domains available.  However, I also needed to be able to add more domains on demand, so working with this on a non-specific project could just add its custom domains without having to edit the code, or customise configuration files

To use:
  Without any custom domains, *.docker.local will resolve to 127.0.0.1
  - ./run-dns.sh
  If you wanted a custom domain apart from *.docker.local, use it like this
  - ./run-dns.sh -d antimatter-studios.local
  
To test:
  - ping something.docker.local
  - ping whatever.antimatter-studios.local
  
The script is prepared to work with linux, a mac version will come soon.
