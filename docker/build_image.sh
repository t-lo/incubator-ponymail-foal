#!/bin/bash
#
# Compat docker build file for legacy systems w/o "docker buildx build".
# Using legacy build will ignore the Dockerfile.alpine.dockerignore file
#   and instead use the stock .dockerignore, resulting in the Alpine docker
#   build to fail.

# Use as subshell because we chdir
( 
    cd "$(dirname "$0")"

    # Ignore dockerignore and use our own, more liberal one
    trap "mv ../.dockerignore.ignore ../.dockerignore" EXIT
    mv ../.dockerignore ../.dockerignore.ignore
    cp Dockerfile.alpine.dockerignore ../.dockerignore

    docker build -f Dockerfile.alpine ../ $@ 
)
