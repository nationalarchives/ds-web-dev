# TNA Website Local Development

A local development setup for all the services required to run `nationalarchives.gov.uk`.

## Quickstart

```sh
# Clone, set up and start all the services
./init.sh
```

After running `./init.sh`, the required services will be cloned into the `services` directory. From there, you may need to add the required `.env` files to get them to work.

## Other commands

```sh
# Pull the latest version of all services that are checked out on the main branch
./pull.sh

# Run the test suite
./test.sh

# Start all the services
./up.sh

# Stop all the services
./down.sh

# Rebuild all the services
./rebuild.sh
```
