# Desiccant
A dehydrated automation engine.

![Desiccant](./desiccant.png)


## Description
Just a bunch BASH scripts an functions that allows me to create or renew X509 certificates effortlessly.

## Schedulers
The only available scheduler is cron, you can enable/disable it globaly in `app.json` or for each servers in `hosts.json`

```JSON
"cron": {
  "enabled": true
}
```

