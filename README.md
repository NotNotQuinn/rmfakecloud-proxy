# rmfakecloud multiproxy

Currently you can:
 - Use official cloud or an instance of rmfakecloud
 - Enable network request logging
 - A prototype insertion of an integration is partially working.
 - More to come (the name will fit)

## Usage
### `multiproxyctl`
This is the main script for controlling rmfakecloud-multiproxy.
```
Usage: multiproxyctl COMMAND
Manage rmfakecloud-multiproxy. Available commands:

    help                    Show this help message.
    status                  Check the current status of rmfakecloud-multiproxy.
    enable                  Enable rmfakecloud-multiproxy.
    disable                 Disable rmfakecloud-multiproxy.
    set-config KEY VAL      Set configuration KEY to VAL.
    get-config [KEY]        Get all configuration, or just KEY.
    validate                Validate the config has no errors.

To view all config keys with documentation:

    rmfakecloud-multiproxy --docs

Some keys have shorthands:

    upstream                UPSTREAM_CLOUD_URL      (string)
    log                     LOG_HTTP_REQUESTS       (bool)
    passthrough             USE_OFFICIAL_CLOUD      (bool)
```
<details>
<summary>

### `rmfakecloud-multiproxy`
You probably won't need to use this binary.
</summary>

```
usage: rmfakecloud-multiproxy [-c config] [-C OPTION=VALUE]...
       rmfakecloud-multiproxy [-h] [-v] [--help] [--version] [--docs]
       rmfakecloud-multiproxy [--validate [--ignore-required]] [-c ...] [-C ...]
  -C OPTION=VALUE
        Explicitly set OPTION=VALUE
        Usable multiple times
  -c config
        Load options from config file
  --ignore-required
        Do not fail validation when required options are unset
        Fails without --validate

Early-exit options:
  --validate
        Exit after all configs are loaded and validated
  --docs
        Print documentation for config options and exit
  -h, --help
        Print this help message and exit
  -v, --version
        Print version and exit
```
</details>

<details>
<summary>

### `installer.sh`

Install and uninstall script
</summary>

```
rmFakeCloud multiproxy installer

Usage:

install
    install rmFakeCloud multiproxy
    Use `multiproxyctl enable` to enable

uninstall
    disable, uninstall, removes everything created by the installer
    Does not remove configs created by `multiproxyctl`
```
</details>

### Example

```console
root@reMarkable: ~$ # Setting a value restarts rmfakecloud-multiproxy
root@reMarkable: ~$ multiproxyctl set-config log true
LOG_HTTP_REQUESTS=true

root@reMarkable: ~$ multiproxyctl set-config upstream https://rm.example.com
UPSTREAM_CLOUD_URL=https://rm.example.com

root@reMarkable: ~$ multiproxyctl get-config
# config dump Thu Aug 24 21:51:58 UTC 2023
# file: /opt/etc/rmfakecloud-multiproxy/config
TLS_CERTIFICATE_FILE=/opt/var/rmfakecloud-multiproxy/rmfakecloud-multiproxy.bundle.crt
TLS_KEY_FILE=/opt/var/rmfakecloud-multiproxy/rmfakecloud-multiproxy.key
PROXY_LISTEN_ADDR=127.0.42.10
UPSTREAM_CLOUD_URL=https://rm.example.com
LOG_HTTP_REQUESTS=true
USE_OFFICIAL_CLOUD=false
```

## Config file
Note: This is probably out of date

Run `rmfakecloud-multiproxy --docs` to generate a config file with all options and documentation.

Config file syntax is very simple and meant to be easy to parse:
 - `KEY=VALUE` trailing tabs and spaces trimmed
 - A bangbang (`!!`) immediately following the equal sign signifies
   a configuration error. Ex: `TLS_KEY_FILE=!!must be set explicitly`
 - Comment lines start with `#`
 - Blank lines allowed

`-C` gets priority over `-c` regardless of order.

<details>
<summary>

### Default config file

Output of `rmfakecloud-multiproxy --docs`

`multiproxyctl` will set the required options the first time you run `multiproxyctl enable`.
</summary>

```env
# rmfakecloud-multiproxy config documentation
# Run `rmfakecloud-multiproxy --docs` to generate this file.
# These docs also happen to be a valid config file that
# includes all options for rmfakecloud-multiproxy v0.0.3-59-g69dd298

# Note: Most of the time, `multiproxyctl` will generate
# and populate the required fields for you after generating
# certs when you run `multiproxyctl enable` for the first time.

# Syntax:
#   KEY=VALUE trailing tabs and spaces trimmed
#   A bangbang (!!) immediately following the equal sign signifies
#     a configuration error. Ex: TLS_KEY_FILE=!!must be set explicitly
#   Comments use '#' as first character on line
#   Blank lines allowed

# Documentation:

# TLS certificate file (.crt) that was generated by multiproxyctl.
# Certificates are self-signed, so they must be installed on the system
# else they will be untrusted.
TLS_CERTIFICATE_FILE=!!must be set explicitly

# TLS key file (.key) that was generated by multiproxyctl.
TLS_KEY_FILE=!!must be set explicitly

# Address to listen for TCP connections.
# multiproxyctl patches /etc/hosts for 127.0.42.10
# so you likely want that. Do not include a port.
PROXY_LISTEN_ADDR=!!must be set explicitly

# Upstream rmfakecloud instance to proxy traffic towards.
# Ignored if USE_OFFICIAL_CLOUD=true.
UPSTREAM_CLOUD_URL=

# Logs network requests and responses.
# Works for rmfakecloud instances and the official cloud.
# Intended mostly for developers, not recommended to keep
# on all the time. `journalctl -u multiproxy -f` to view logs.
# Boolean `true` or `false`
LOG_HTTP_REQUESTS=false

# Pass requests through to the correct destination.
# Boolean `true` or `false`
USE_OFFICIAL_CLOUD=false
```
</details>



## Development and troubleshooting

View network logs on the device through wireshark and ssh:
https://superuser.com/questions/1585650/using-wireshark-with-remote-interface

Helpful for finding new domains to add to the proxy. Not much else.

If you are trying to develop on 3.X (like me), I recommend you dual boot 2.X with toltec
and add a bind-mount on your 3.X system. Then you can install netcat and tcpdump for the above to work.
(you could probably also download the binaries manually)
This gives you access to the binaries you installed on 2.X when booted into 3.X.
This includes `opkg`. DO NOT USE OPKG ON 3.X.
I haven't tried it and I have been warned, so I'm not going to try it.

```bash
# These are possibly very bad commands to run on 3.x; use them at your own risk
bash -l # Start a new login shell; Default shell can sometimes be 'sh'
source ~/.local/bin/toltecctl
add-bind-mount /home/root/.entware /opt
exit # exit the subshell
```

To undo the above:

```bash
bash -l
source ~/.local/bin/toltecctl
remove-bind-mount /opt
exit
```

## Compatibility with rmfakecloud-proxy

The configuration files are entirely separate, as I consider this not a replacement
of rmfakecloud-proxy but a new option with more features. rmfakecloud-proxy is more lightweight
and some people may prefer it. Command line options for `multiproxyctl` are semi-compatible.
Command line options for `rmfakecloud-multiproxy` are not compatible.

All binary names and systemd services are new and don't conflict with rmfakecloud-proxy,
however both proxies cannot run at the same time because they both need to listen on port :443.

TODO: Probably a good idea to change the listen address that multiproxyctl uses
