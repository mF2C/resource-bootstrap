#!/bin/sh

set -e
set -u

IMAGE_NAME=mf2c/resource-bootstrap

echo "Building $IMAGE_NAME:latest"
docker build -t "$IMAGE_NAME:latest" .

git tag --points-at HEAD | while read tag; do
    echo "Tagging $IMAGE_NAME:latest as $IMAGE_NAME:$tag"
    docker tag "$IMAGE_NAME:latest" "$IMAGE_NAME:$tag"
    echo "    pushing..."
    docker push "$IMAGE_NAME:$tag"
done

echo "Pushing $IMAGE_NAME:latest..."
docker push "$IMAGE_NAME:latest"
