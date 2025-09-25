# modern-box

Лёгкий operational toolbox контейнер: `nats` CLI, `curl`, `jq`, `openssl`, `ca-certificates`.
Предназначен для:
- Одноразовых Kubernetes Jobs (bootstrap / диагностика)
- Отладки JetStream / KV / Streams
- Интерактивной проверки сетевых путей и TLS

Не предназначен как долгоживущий sidecar.

## Состав
- Alpine (digest pinned)
- nats CLI (версия через ARG + SHA256 проверка)
- curl, jq, unzip, coreutils, openssl

## OCI Лейблы
В Dockerfile присутствуют стандартные OCI labels: `title, description, source, version, revision, authors, licenses`.

## Быстрый старт
```bash
# Локально (только для тестов, prod через GHCR):
docker build -t modern-box:dev .

# Подключиться к кластерному NATS (пример):
docker run --rm -it \
  -e NATS_URL=nats://nats.backend-dev.svc.cluster.local:4222 \
  modern-box:dev nats --help
```

## Пример Kubernetes Job
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: js-inspect
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: modern-box
        image: ghcr.io/zsheak/modern-box@sha256:<DIGEST>
        command: ["/bin/sh","-c"]
        args:
          - nats -s "$NATS_URL" stream ls; echo 'done';
        env:
          - name: NATS_URL
            value: nats://nats.backend.svc.cluster.local:4222
```

## Supply chain
- Digest pinning (используйте `@sha256:` в манифестах)
- (Опционально) SBOM Syft и Trivy в CI (см. workflow)
- Подпись cosign keyless (если настроен OIDC)

## English (brief)
`modern-box` is a minimal operations toolbox image containing the NATS CLI, curl, jq, and OpenSSL. Use it for ad‑hoc Jobs and diagnostics; not meant to be a long‑running sidecar.

## Версионирование
`MODERN_BOX_VERSION` аргумент билда. Рекомендуется маппить git tag -> OCI label.

## Лицензия
Apache-2.0. См. `LICENSE`.
