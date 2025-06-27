FROM golang:1.24.3-alpine3.20 as hcloud-builder

# renovate: datasource=github-releases depName=hcloud packageName=hetznercloud/cli versioning=semver-coerced
ARG HCLOUD_CLI_VERSION=v1.51.0
RUN GOBIN=/usr/local/bin/ go install github.com/hetznercloud/cli/cmd/hcloud@${HCLOUD_CLI_VERSION}

FROM ghcr.io/runatlantis/atlantis:v0.35.0 as final

USER root

# renovate: datasource=pypi depName=azure-cli packageName=azure-cli versioning=semever
ARG AZURE_CLI_VERSION=2.74.0
# hadolint ignore=DL3018,DL3013
RUN apk add --no-cache py3-pip && \
    apk add --no-cache --virtual .azure-cli-deps gcc musl-dev python3-dev libffi-dev openssl-dev cargo make && \
    pip install --upgrade --no-cache-dir --break-system-packages pip && \
    pip install --no-cache-dir --break-system-packages azure-cli==${AZURE_CLI_VERSION} && \
    apk del .azure-cli-deps;


ENV HASHICORP_PRODUCT="terraform"
# renovate: datasource=github-releases depName=terraform packageName=hashicorp/terraform versioning=semver-coerced
ARG TERRAFORM_VERSION=v1.12.2
# hadolint ignore=DL3018,DL3003,DL4006,DL3013
RUN ARCH="amd64" && \
    if [ "$(uname -m)" = "aarch64" ]; then ARCH="arm64"; fi && \
    apk add --update --virtual .deps --no-cache gnupg && \
    cd /tmp && \
    TERRAFORM_VERSION=${TERRAFORM_VERSION#"v"} && \
    wget -q https://releases.hashicorp.com/"${HASHICORP_PRODUCT}"/"${TERRAFORM_VERSION}"/"${HASHICORP_PRODUCT}"_"${TERRAFORM_VERSION}"_linux_"${ARCH}".zip && \
    wget -q https://releases.hashicorp.com/"${HASHICORP_PRODUCT}"/"${TERRAFORM_VERSION}"/"${HASHICORP_PRODUCT}"_"${TERRAFORM_VERSION}"_SHA256SUMS && \
    wget -q https://releases.hashicorp.com/"${HASHICORP_PRODUCT}"/"${TERRAFORM_VERSION}"/"${HASHICORP_PRODUCT}"_"${TERRAFORM_VERSION}"_SHA256SUMS.sig && \
    wget -qO- https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import && \
    gpg --verify "${HASHICORP_PRODUCT}"_"${TERRAFORM_VERSION}"_SHA256SUMS.sig "${HASHICORP_PRODUCT}"_"${TERRAFORM_VERSION}"_SHA256SUMS && \
    grep "${HASHICORP_PRODUCT}"_"${TERRAFORM_VERSION}"_linux_"${ARCH}".zip "${HASHICORP_PRODUCT}"_"${TERRAFORM_VERSION}"_SHA256SUMS | sha256sum -c && \
    unzip /tmp/"${HASHICORP_PRODUCT}"_"${TERRAFORM_VERSION}"_linux_"${ARCH}".zip -d /tmp && \
    mv /tmp/"${HASHICORP_PRODUCT}" /usr/bin/"${HASHICORP_PRODUCT}" && \
    rm -f /tmp/"${HASHICORP_PRODUCT}"_"${TERRAFORM_VERSION}"_linux_"${ARCH}".zip "${HASHICORP_PRODUCT}"_"${TERRAFORM_VERSION}"_SHA256SUMS "${TERRAFORM_VERSION}"/"${HASHICORP_PRODUCT}"_"${TERRAFORM_VERSION}"_SHA256SUMS.sig && \
    apk del .deps

USER atlantis

COPY --from=hcloud-builder /usr/local/bin/hcloud /usr/bin/hcloud
