# TNA Website Local Development

A local development setup for all the services required to run `nationalarchives.gov.uk`.

## Quickstart

```sh
# Clone, set up and start all the services
./init.sh
```

After running `./init.sh`, the required services will be cloned into the `services` directory.

Services that have an `example.env` file will have a copy made for `.env`. From there, you may need to add the required variables in your `.env` files to get the service to work.

## Other commands

```sh
# Pull the latest version of all services that are checked out on the main branch
./pull.sh

# Show which branches your services have checked out
./branches.sh

# Run the test suite
./test.sh

# Start all the services
./up.sh

# Stop all the services
./down.sh

# Show the status of all services
./status.sh

# Rebuild all the services
./rebuild.sh

# Prune old branches for all services
./prune.sh
```
