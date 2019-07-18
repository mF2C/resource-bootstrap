# mF2C resource bootstrapper

This repository provides a way to pre-populate resources, such as users and services, into mF2C.

It is deployed alongside mF2C as a container, executing the bootstrap script on start.


## Usage and testing

Add JSON resources to `resources/{services,}` as they would be send to CIMI manually.

To test, run the container locally and point it to a running instance of mF2C from the outside:

```bash
docker build -t mf2c-resource-bootstrap .
docker run -it -e CIMI_HOST=192.0.2.2 -e CIMI_PORT=80 mf2c-resource-bootstrap
```


## Building and publishing the image

This repository does not a CI integration. Building is manual through `build-publish.sh`, which always builds
`mf2c/resource-bootstrap:latest` and searches for any git tags present on the current commit, and if any are present, 
also tags and pushes them.

```bash
git tag -a v1.2.3  # optional, also creates a Docker tag
git push --tags
./build-publish.sh
```


## Caveats

* This uses the CIMI administrator override.
* Duplicate resources will be created if they are submitted multiple times.
