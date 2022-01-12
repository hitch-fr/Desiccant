[![Desiccant](./assets/desiccant.svg)](https://hitch.fr)

<p align="center">
  <a href="https://hitch.fr"><img src="./assets/version.svg" alt="Version"></a>
  <a href="https://hitch.fr"><img src="./assets/build_failed.svg" alt="Build Status"></a>
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

## Release

Desiccant will be released soon, actually we already been using it for months at hitch.fr. Nonetheless, we will be committing small parts at a time and while doing so, we will be refactoring, commenting and double check for possible security issues.

## Features

Any improvement suggestion is welcome, just open an issue or send an email at [support@hitch.fr](mailto:support@hitch.fr)

- Easy to use locally
- Easy to use remotely
- Configurable email reports
- Human readable Cron configuration


## Hooks

Hooks can be set globally in `configs/certs.json` and can be override on a per certificate basis in `configs/certificates/my_cert.json`.
To begin with we will only support the [Dehydrated-ovh](https://github.com/hitch-fr/dehydrated-ovh.git) hooks that we wrote but we plan to make it really easy to use any hooks supported by [Dehydrated](https://github.com/dehydrated-io/dehydrated.git) and eventually we will probably insert hooks that dont add any dependencies and that can be configured from Desiccant by environnement variables.

## Configure

### Email report
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

### Synchronize
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

- [ ] Find and set up pretty decent defaults that suit as many people needs as possible
- [ ] Identify and correct misconceptions ( we are not security experts )
- [ ] Identify and patch security issues
- [ ] Identify scripts weaknesses and improve their performances

### version 0.2

Basically, we will try to improve Desiccant behavior and make it more flexible. the main idea is to make sure that Desiccant knows how to be forgotten most of the time, when everythings goes well, but sends the right information at the right time when something went wrong and a human being should intervene.

- [ ] implement the option `--host $host $cert` for the renew command
- [ ] add daily cron jobs for particular certificates when renewal fails and expiration is near
- [ ] send SMS reports when when a cert expiry is soon
- [ ] when everything is done, bring a coffee to the sysadmins in the break room