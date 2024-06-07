FROM golang:1.22.4-alpine3.20 as hcloud-builder

# renovate: datasource=github-releases depName=cli packageName=hetznercloud/cli versioning=semver
ARG HCLOUD_CLI_VERSION="v1.43.1"
RUN GOBIN=/usr/local/bin/ go install github.com/hetznercloud/cli/cmd/hcloud@${HCLOUD_CLI_VERSION}

FROM ghcr.io/runatlantis/atlantis:v0.28.1 as final

USER root

ARG AZURE_CLI_VERSION="2.61.0"
RUN apk add --no-cache py3-pip && \
    apk add --no-cache --virtual .azure-cli-deps gcc musl-dev python3-dev libffi-dev openssl-dev cargo make && \
    pip install --upgrade --no-cache --break-system-packages pip && \
    pip install --no-cache-dir --break-system-packages azure-cli==${AZURE_CLI_VERSION} && \
    apk del .azure-cli-deps;

ENV HASHICORP_PRODUCT="terraform"
ARG VERSION="1.8.4"
RUN ARCH=amd64 && \
    if [ "$(uname -m)" = "aarch64" ]; then ARCH=arm64; fi && \
    apk add --update --virtual .deps --no-cache gnupg && \
    cd /tmp && \
    wget https://releases.hashicorp.com/${HASHICORP_PRODUCT}/${VERSION}/${HASHICORP_PRODUCT}_${VERSION}_linux_${ARCH}.zip && \
    wget https://releases.hashicorp.com/${HASHICORP_PRODUCT}/${VERSION}/${HASHICORP_PRODUCT}_${VERSION}_SHA256SUMS && \
    wget https://releases.hashicorp.com/${HASHICORP_PRODUCT}/${VERSION}/${HASHICORP_PRODUCT}_${VERSION}_SHA256SUMS.sig && \
    wget -qO- https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import && \
    gpg --verify ${HASHICORP_PRODUCT}_${VERSION}_SHA256SUMS.sig ${HASHICORP_PRODUCT}_${VERSION}_SHA256SUMS && \
    grep ${HASHICORP_PRODUCT}_${VERSION}_linux_${ARCH}.zip ${HASHICORP_PRODUCT}_${VERSION}_SHA256SUMS | sha256sum -c && \
    unzip /tmp/${HASHICORP_PRODUCT}_${VERSION}_linux_${ARCH}.zip -d /tmp && \
    mv /tmp/${HASHICORP_PRODUCT} /usr/bin/${HASHICORP_PRODUCT} && \
    rm -f /tmp/${HASHICORP_PRODUCT}_${VERSION}_linux_${ARCH}.zip ${HASHICORP_PRODUCT}_${VERSION}_SHA256SUMS ${VERSION}/${HASHICORP_PRODUCT}_${VERSION}_SHA256SUMS.sig && \
    apk del .deps

USER atlantis

COPY --from=hcloud-builder /usr/local/bin/hcloud /usr/bin/hcloud
