# modern-box

Minimal operational toolbox image: **NATS CLI**, **curl**, **jq**, **openssl**, **coreutils**, trusted **CA certificates**.

> Purpose-built for short‑lived Kubernetes Jobs (bootstrap, diagnostics, JetStream / KV inspection). **Not** intended as a permanent sidecar.

## Why another toolbox?
Most generic debug images are either too heavy (busybox + a lot of extras) or lack deterministic supply chain controls. `modern-box` focuses on:

* Deterministic build (Alpine pinned by digest)
* Verified NATS CLI binary (version + SHA256 check)
* Minimal yet practical surface (network + JSON + crypto)
* Strong OCI metadata (labels, revision, author)
* Ready for secure pinning in GitOps (digest only)

## Features
* Pinned Alpine base image (`ARG ALPINE_DIGEST`)
* NATS CLI with checksum verification before install
* Non‑root user (uid/gid 65532)
* Clean shell entrypoint (`/bin/sh`), starts interactive easily
* Pre-configured `NATS_URL` env (override per Job/Pod)
* OCI labels: title, description, source, version, revision, authors, licenses
* Optional SBOM (Syft) + vulnerability scan (Trivy) via GitHub Actions
* Optional keyless Cosign signature (OIDC)

## Image Tags & Digest
Build workflow pushes:
* `ghcr.io/zsheak/modern-box:<git-sha>`
* Optionally `:main` (mutable convenience tag)
ALWAYS deploy with the immutable digest form:
```
ghcr.io/zsheak/modern-box@sha256:<DIGEST>
```

## Quick Start (local test)
```bash
docker build -t modern-box:dev .
docker run --rm -it modern-box:dev nats --version
```

Connect to a remote NATS:
```bash
docker run --rm -it \
  -e NATS_URL=nats://nats.backend-dev.svc.cluster.local:4222 \
  modern-box:dev nats stream ls
```

## Kubernetes Job Example
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

## NATS CLI Cheat Sheet
```bash
# Streams
nats -s $NATS_URL stream ls
nats -s $NATS_URL stream info <STREAM>

# JetStream account report
nats -s $NATS_URL account info

# Key-Value buckets
nats -s $NATS_URL kv ls
nats -s $NATS_URL kv info <BUCKET>
nats -s $NATS_URL kv get <BUCKET> <KEY>

# Consumers
nats -s $NATS_URL consumer ls <STREAM>
nats -s $NATS_URL consumer info <STREAM> <CONSUMER>
```

## Supply Chain / Security
| Aspect | Detail |
|--------|--------|
| Base | Alpine pinned via digest (`ALPINE_DIGEST`) |
| Binary integrity | SHA256 verification for NATS CLI zip |
| User | Non-root (modernbox:modernbox) |
| SBOM | Generated with Syft in CI (artifact) |
| Vulnerabilities | Trivy scan fails build on HIGH/CRITICAL |
| Signature | Cosign keyless (if OIDC available) |
| Deployment | Digest-only pin in Kubernetes |

## Versioning
`MODERN_BOX_VERSION` (build arg) + `org.opencontainers.image.version` label. Recommend mapping Git tags to semantic versions and adding an annotated tag when releasing.

## Deterministic Rebuild
Rebuild only changes if:
1. `ALPINE_DIGEST` updated
2. `NATSCLI_VERSION` or its SHA256 changes
3. Dockerfile / metadata altered
4. Build args (`MODERN_BOX_VERSION`, `GIT_SHA`, `BUILD_AUTHOR`) differ

## Obtaining the Digest After CI
From GitHub Actions log step “Show digest” or locally:
```bash
docker pull ghcr.io/zsheak/modern-box:main
docker inspect --format='{{index .RepoDigests 0}}' ghcr.io/zsheak/modern-box:main
```

## Future Enhancements (Ideas)
* Optional `busybox-extras` (behind build arg)
* Multi-arch (arm64) build matrix
* Embedded lightweight `kubectl` (separate flavor, not default)
* Tag automation from conventional commits

## Contributing
Open an issue or PR — keep diffs minimal and deterministic. No unpinned images.

## License
MIT — see `LICENSE`.

---
Feel free to propose additional minimal tools as long as they keep the image lean and reproducible.
