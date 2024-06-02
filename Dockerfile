FROM golang:1.22.3-alpine3.20 as hcloud-builder

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

ARG PRODUCT="terraform"
ARG VERSION="1.8.4"
RUN ARCH=amd64 && \
    if [ "$(uname -m)" = "aarch64" ]; then ARCH=arm64; fi && \
    apk add --update --virtual .deps --no-cache gnupg && \
    cd /tmp && \
    wget https://releases.hashicorp.com/${PRODUCT}/${VERSION}/${PRODUCT}_${VERSION}_linux_${ARCH}.zip && \
    wget https://releases.hashicorp.com/${PRODUCT}/${VERSION}/${PRODUCT}_${VERSION}_SHA256SUMS && \
    wget https://releases.hashicorp.com/${PRODUCT}/${VERSION}/${PRODUCT}_${VERSION}_SHA256SUMS.sig && \
    wget -qO- https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import && \
    gpg --verify ${PRODUCT}_${VERSION}_SHA256SUMS.sig ${PRODUCT}_${VERSION}_SHA256SUMS && \
    grep ${PRODUCT}_${VERSION}_linux_${ARCH}.zip ${PRODUCT}_${VERSION}_SHA256SUMS | sha256sum -c && \
    unzip /tmp/${PRODUCT}_${VERSION}_linux_${ARCH}.zip -d /tmp && \
    mv /tmp/${PRODUCT} /usr/bin/${PRODUCT} && \
    rm -f /tmp/${PRODUCT}_${VERSION}_linux_${ARCH}.zip ${PRODUCT}_${VERSION}_SHA256SUMS ${VERSION}/${PRODUCT}_${VERSION}_SHA256SUMS.sig && \
    apk del .deps

USER atlantis

COPY --from=hcloud-builder /usr/local/bin/hcloud /usr/bin/hcloud
