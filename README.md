[![Desiccant](./assets/desiccant.svg)](https://hitch.fr)

<p align="center">
  <a href="https://hitch.fr"><img src="./assets/version.svg" alt="Version"></a>
  <a href="https://hitch.fr"><img src="./assets/build_failed.svg" alt="Build Status"></a>
  <a href="https://hitch.fr"><img src="./assets/status_unstable.svg" alt="Latest Stable"></a>
  <a href="https://hitch.fr"><img src="./assets/license.svg" alt="License"></a>
</p>

## About Desiccant

Make your certificates management a breeze. Desiccant has a comprehensive JSON configuration system that let you effortlessly create, renew or automate your X509 certificates with only pure BASH. If like us at hitch.fr, you don't necessarily want to install technologies like snap or python on each of your servers, Desiccant could meet your needs.

Under the hood, Desiccant uses

- [JQ](https://github.com/stedolan/jq.git) as a JSON Processor
- [Bash-TPL](https://github.com/TekWizely/bash-tpl.git) as a templating engine
- [Dehydrated](https://github.com/dehydrated-io/dehydrated.git) as an ACME client
- [Dehydrated-ovh](https://github.com/hitch-fr/dehydrated-ovh.git) as a Dehydrated hook

## Release

Desiccant will be released soon, actually we already been using it for months at hitch.fr. Nonetheless, I will be committing small parts at a time and while doing so, I will be refactoring, commenting and double check for possible security issues.

## Hooks

Hooks can be set globally in `configs/certs.json` and can be override on a per certificate basis in `configs/certificates/my_cert.json`.
To begin with we will only support the [Dehydrated-ovh](https://github.com/hitch-fr/dehydrated-ovh.git) hooks that we wrote but we plan to make it really easy to use any hooks supported by [Dehydrated](https://github.com/dehydrated-io/dehydrated.git) and eventually we will probably insert hooks that dont add any dependencies and that can be configured from Desiccant by environnement variables.
