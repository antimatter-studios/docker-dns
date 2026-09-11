# docker-dns

The local DNS server that [ddt](https://github.com/antimatter-studios/docker-dev-tools) runs: dnsmasq under supervisord, answering for the development TLDs ddt configures (for example `*.develop`) and forwarding everything else to your normal DNS servers.

## Using it

Through ddt, which starts the container, writes a dnsmasq file for each TLD and points your system's resolver at it:

```bash
ddt dns add-tld develop
ddt dns start
```

## Developing it

```bash
chore build   # build the image
chore test    # build it, run it the way ddt does, and check a TLD resolves over UDP and TCP
```

CI runs `chore test` on every pull request. A pull request merges itself once CI passes, and main is then published to `ghcr.io/antimatter-studios/docker-dns`.