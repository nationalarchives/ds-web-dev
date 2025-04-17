# TNA Website Local Development

A local development setup for all the services required to run `nationalarchives.gov.uk`.

## Quickstart

```sh
./init.sh
```

The required services will be cloned into the `services` directory. From there, you may need to add the required `.env` files to get them to work.

## Update all services

```sh
# Pull the latest version of all services that are checked out on the main branch
./pull.sh
```
