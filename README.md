[![Desiccant](./assets/desiccant.svg)](https://hitch.fr)

<p align="center">
  <a href="https://hitch.fr"><img src="./assets/version.svg" alt="Version"></a>
  <a href="https://hitch.fr"><img src="./assets/build_passing.svg" alt="Build Status"></a>
  <a href="https://hitch.fr"><img src="./assets/status_unstable.svg" alt="Latest Stable"></a>
  <a href="https://hitch.fr"><img src="./assets/license.svg" alt="License"></a>
</p>

## About Desiccant

Make your certificates management a breeze. Desiccant has a comprehensive JSON configuration system that let you effortlessly create, renew or automate your X509 certificates with only pure BASH. If like us at hitch.fr, you don't necessarily want to install technologies like snap or python on small servers just to be able to issue a couple of wildcard certificates, Desiccant could meet your needs.

Under the hood, Desiccant uses

- [JQ](https://github.com/stedolan/jq.git) as a JSON Processor
- [Bash-TPL](https://github.com/TekWizely/bash-tpl.git) as a templating engine
- [Dehydrated](https://github.com/dehydrated-io/dehydrated.git) as an ACME client
- [Dehydrated-ovh](https://github.com/hitch-fr/dehydrated-ovh.git) as a Dehydrated hook

## Features

Any improvement suggestion is welcome, just open an issue or send an email at [support@hitch.fr](mailto:support@hitch.fr)

- Easy to use locally
- Easy to use remotely
- Configurable email reports
- Human readable Cron configuration

## Installation

```bash
git clone --recursive https://github.com/hitch-fr/Desiccant.git
cd Desiccant
cp configs/examples/hosts.json configs/hosts.json
```

Then configure your hosts as described in the [configuration](#configuration) section

## Update

Just run the following commands from the Desiccant directory

```bash
git pull
git submodule update --remote
```

## Configuration

### Hosts configurations

Create or copy the `hosts.json` file from the `configs/examples` directory.
The only required values are `name` and `certificates`. The `name` should be the hostname (as printed by the hostname command) of the server where you intend to run the renew command for the given `certificates` which is simply an array referencing the configuration files of the certificates in the `configs/certificates` directory.

```json
{
  "local": {
    "name": "localhost_name",
    "certificates": [
      "local.json"
    ]
  },

  "remote": {
    "name": "srv1.example.com",
    "sync": true,
    "renew_on_sync": false,

    "ssh": {
      "host": "example.com",
      "port": 22222,
      "user": "root"
    },

    "certificates": [
      "example.com.json",
      "another.example.org.json"
    ]

  }
}
```

### Certificates configuration

The only required value is the fully qualified domain name `fqdn`. Your registrar credentials can be added globally in the `configs/certs.json` file like any other certificate related configuration.

```json
{
  "fqdn": "example.com",

  "aliases": [
    "example.com",
    "any.subdomain.example.com",
    "*.example.com"
  ]
}
```

### Registrars

The registrar can be set globally in `configs/certs.json` and can be override on a per certificate basis in `configs/certificates/my_cert.json`.

The default registrar is OVH, To configure it, you just have to fill in your credentials

> Note that when synchronizing Desiccant with remote servers all configuration files are also synchronized, this may lead to security issues. In a near future Desiccant will probably only sync necessary files.

> You should limit access to your configuration files to only necessary users. A `chmod 600` would probably be a good idea.

```json
{
  "fqdn": "example.com",

  "ovh":{
    "endpoint": "ovh-eu",
    "key": "<MY_OVH_KEY>",
    "secret": "<MY_OVH_SECRET_KEY>",
    "consumer_key": "<MY_OVH_CONSUMER_KEY>"
  }
}
```

### Custom registrar

Under the hood Desiccant uses the [Dehydrated-ovh](https://github.com/hitch-fr/dehydrated-ovh.git) Dehydrated hooks script to handle the DNS Zone management so you can use any hooks you would use with Dehydrated. 

```json
{
  "registrar": "whatever",

  "whatever":{
    "hooks": "/absolute/path/to/the/hooks.sh"
  }
}
```

> In a sync scenario make sure to fill in the path of the hooks in the remote server

### Email reports
```json
{
  "my_server": {
    "email": {
      "enabled": true,
      "host": "smtp://mailserver.com",
      "user": "server@mailserver.com",
      "password": "YOUR_SMTP_PASSWORD",
      "from": "server@mailserver.com",
      "to": "sysadmin@example.com"
    }
  }
}
```

### Cron
```json
{
  "my_server": {
    "cron": {
      "enabled": true,
      "frequency": "everyday @ 8"
    }
  }
}
```

## Usage

### Run locally
```bash
./run renew
```

### Schedule locally
```bash
sudo ./run cron
```

### Synchronize and schedule remotely
```bash
./run sync
```

## Known compatible operating systems and bash versions

- Debian buster 10.11 with GNU bash, version 5.0.3
- Debian bullseye 11.0 with GNU bash, version 5.1.8

> We would be glad to hear about issues on other operating systems or bash versions to possibly extend compatibilities.

## Roadmap

### version 0.1

Basically, we'll just try to make Desiccant work well for most use cases and make it easy for anyone to set up, customize and use. Thanks for helping us in all that by opening issues or by sending emails at [support@hitch.fr](mailto:support@hitch.fr)

- [ ] Add the `cron` command
- [ ] Add the `remote_run` command
- [ ] Find and set up pretty decent defaults that suit as many people needs as possible
- [ ] Identify and correct misconceptions ( we are not security experts )
- [ ] Identify and patch security issues

### version 0.2

Basically, we will try to improve Desiccant behavior and make it more flexible. the main idea is to make sure that Desiccant knows how to be forgotten most of the time, when everythings goes well, but sends the right information at the right time when something went wrong and a human being should intervene.

- [ ] implement the option `--host $host $cert` for the renew command
- [ ] add daily cron jobs for particular certificates when renewal fails and expiration is near
- [ ] send SMS reports when a cert expiry is soon
- [ ] when everything is done, bring a coffee to the sysadmins in the break room