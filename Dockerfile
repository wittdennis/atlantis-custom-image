FROM ghcr.io/runatlantis/atlantis:v0.28.1

USER root

ARG AZURE_CLI_VERSION="2.61.0"
RUN apk add --no-cache py3-pip && \
    apk add --no-cache --virtual .azure-cli-deps gcc musl-dev python3-dev libffi-dev openssl-dev cargo make && \
    pip install --upgrade --no-cache --break-system-packages pip && \
    pip install --no-cache-dir --break-system-packages azure-cli==${AZURE_CLI_VERSION} && \
    apk del .azure-cli-deps;

USER atlantis
