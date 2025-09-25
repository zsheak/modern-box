# modern-box: lightweight operational toolbox image
# Contains: nats CLI, curl, jq, openssl, ca-certificates.
# Use for diagnostics / one-off Kubernetes Jobs, not a persistent sidecar.

ARG ALPINE_DIGEST=sha256:4bcff63911fcb4448bd4fdacec207030997caf25e9bea4045fa6c8c44de311d1
ARG NATSCLI_VERSION=0.3.0
ARG NATSCLI_SHA256=965a1a68a67a20cf9513f6e3fec612bbef81d25d519177c460afddbcf72e1d4b
ARG MODERN_BOX_VERSION=0.1.0
ARG BUILD_AUTHOR="Zakhar Shevliakov"
ARG GIT_SHA=dev

FROM alpine@${ALPINE_DIGEST} AS base
ARG NATSCLI_VERSION
ARG NATSCLI_SHA256
ARG MODERN_BOX_VERSION
ARG BUILD_AUTHOR
ARG GIT_SHA
WORKDIR /work

RUN set -euo pipefail \
    && apk add --no-cache ca-certificates curl jq unzip coreutils openssl \
    && update-ca-certificates

RUN set -euo pipefail \
    && ARCH=amd64 OS=linux \
    && ZIP="nats-${NATSCLI_VERSION}-${OS}-${ARCH}.zip" \
    && URL="https://github.com/nats-io/natscli/releases/download/v${NATSCLI_VERSION}/$ZIP" \
    && echo "==> Fetch $URL" \
    && curl -sSL -o "$ZIP" "$URL" \
    && echo "${NATSCLI_SHA256}  $ZIP" > sum.txt \
    && sha256sum -c sum.txt \
    && unzip -d extracted "$ZIP" \
    && mv extracted/nats-${NATSCLI_VERSION}-${OS}-${ARCH}/nats /usr/local/bin/nats \
    && chmod +x /usr/local/bin/nats \
    && nats --version

RUN addgroup -g 65532 -S modernbox && adduser -S -D -u 65532 -G modernbox modernbox
USER modernbox:modernbox

ENV HOME=/home/modernbox \
    NATS_URL=nats://localhost:4222

LABEL org.opencontainers.image.title="modern-box" \
    org.opencontainers.image.description="Modern operational toolbox (nats-cli + curl + jq)" \
    org.opencontainers.image.source="https://github.com/zsheak/modern-box" \
    org.opencontainers.image.version="${MODERN_BOX_VERSION}" \
    org.opencontainers.image.revision="${GIT_SHA}" \
    org.opencontainers.image.authors="${BUILD_AUTHOR}" \
    org.opencontainers.image.licenses="Apache-2.0"

WORKDIR /workspace
ENTRYPOINT ["/bin/sh"]
CMD ["-c","nats --help || true; echo 'modern-box ready'; exec /bin/sh"]
