FROM docker.io/iiidev/iii:@iii-version@ AS engine

FROM docker.io/library/node:26-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libgomp1 tini \
    && rm -rf /var/lib/apt/lists/*

COPY --from=engine /app/iii /usr/local/bin/iii

WORKDIR /opt/agentmemory

# Keep the SDK on the engine's protocol version. Local embeddings require
# Transformers.js and its native optional dependencies.
RUN printf '%s\n' '{"private":true,"overrides":{"iii-sdk":"@iii-version@","@huggingface/transformers":"4.2.0"}}' > package.json \
    && npm install --omit=dev --include=optional --no-fund --no-audit \
        @agentmemory/agentmemory@@agentmemory-version@ @huggingface/transformers@4.2.0 \
    && npm cache clean --force

ENV NODE_ENV=production HOME=/home/agentmemory
USER 65532:65532

# iii compose ignores SIGTERM as PID 1. It writes a lockfile beside its manifest
# and the engine rewrites its configuration, so neither can stay read-only.
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sh", "-c", "install -m 600 /app/iii-observability.yaml /app/config/iii-observability.yaml && install -m 600 /app/worker-compose.yaml /data/worker-compose.yaml && exec iii --no-update-check compose --namespace agentmemory --up --file /data/worker-compose.yaml"]
