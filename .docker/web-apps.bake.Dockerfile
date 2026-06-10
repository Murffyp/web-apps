# ==============================================================================
# MODULE DOCKERFILE
# This file is not meant to be built standalone. It is consumed by the 
# docker-bake.hcl files in the parent monorepos.
# ==============================================================================

ARG PRODUCT_VERSION
ARG BUILD_ROOT

#### BASE ####
FROM ubuntu:24.04 AS web-base
    RUN apt-get update && \
        apt-get install -y ca-certificates curl gnupg openjdk-21-jdk wget zip brotli bzip2 && \
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
        apt-get install -y nodejs && \
        npm install -g @yao-pkg/pkg grunt-cli && \
        rm -rf /var/lib/apt/lists/*

#### WEB-APPS ####
FROM web-base AS web-apps
    ARG PRODUCT_VERSION
    ARG BUILD_ROOT=/package

    COPY build/package*.json /apps/build/
    COPY build/sprites/package*.json /apps/build/sprites/
    COPY build/plugins/grunt-inline/ /apps/build/plugins/grunt-inline/

    RUN --mount=type=cache,target=/root/.npm \
        cd apps/build && \
        npm install


    COPY . /apps

    ENV PRODUCT_VERSION=${PRODUCT_VERSION}
    ENV BUILD_ROOT=${BUILD_ROOT}

    RUN cd apps/translation && \
        python3 merge_and_check.py

    ARG TARGETARCH
    RUN cd apps/build && \
        THEME=euro-office grunt $(if [ "$TARGETARCH" = "arm64" ]; then echo "--skip-imagemin"; fi)
