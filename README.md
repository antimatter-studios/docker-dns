# supervisord-dnsmasq
Supervisord controlled DNSMasq allowing updates for domains without modifying the config

This project was born out of a need to run a dnsmasq docker container to resolve hostnames on my docker containers without wanting to constantly edit the system files to make the domains available.  However, I also needed to be able to add more domains on demand, so working with this on a non-specific project could just add its custom domains without having to edit the code, or customise configuration files

Parameters:
+ -a: The ip alias for the loopback adapter
+ -d: The domain to configure

To Start:
- ./start.sh -a 10.254.254.254 -d api.example.local

To Stop:
- ./stop.sh
- The software must be stopped using the script because it has configured the system to use a nameserver that after the container stops, will no longer be present.  The machine will not be able to correctly resolve hostnames after this point.

Future Ideas:
- Make it possible to configure multiple ip aliases with multiple domains