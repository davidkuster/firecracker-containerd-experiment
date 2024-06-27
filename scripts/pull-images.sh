#!/bin/bash

docker pull deepwonderio/fc-image-builder
docker tag deepwonderio/fc-image-builder fc-image-builder
docker pull deepwonderio/runc-builder
docker tag deepwonderio/fc-image-builder localhost/runc-builder
docker pull public.ecr.aws/firecracker/fcuvm:v35
