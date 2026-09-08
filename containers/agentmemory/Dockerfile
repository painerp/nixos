FROM docker.io/library/node:24-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/agentmemory

# Keep the SDK on the engine's protocol version. Local embeddings require
# Transformers.js and its native optional dependencies.
RUN printf '%s\n' '{"private":true,"overrides":{"iii-sdk":"0.11.2","@huggingface/transformers":"4.2.0"}}' > package.json \
    && npm install --omit=dev --include=optional --no-fund --no-audit \
        @agentmemory/agentmemory@@agentmemory-version@ @huggingface/transformers@4.2.0 \
    && npm cache clean --force

ENV NODE_ENV=production HOME=/home/agentmemory
USER 65532:65532

CMD ["node", "node_modules/@agentmemory/agentmemory/dist/index.mjs"]
