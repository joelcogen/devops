#!/bin/bash -ex
docker buildx use multiplatform-builder || docker buildx create --name multiplatform-builder --driver docker-container --bootstrap --use
docker buildx build -t joelcogen/haproxy_ssl --platform linux/amd64,linux/arm64 --push .
