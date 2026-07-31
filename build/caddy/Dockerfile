ARG GO_VERSION=1.26.5
ARG UV_VERSION=0.4.30
ARG XCADDY_VERSION=v0.4.2

# Named stage so --from can reference it without variable expansion.
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv-bin

FROM golang:${GO_VERSION}-bookworm

ARG XCADDY_VERSION

COPY --from=uv-bin /uv /usr/local/bin/uv

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates file && \
    rm -rf /var/lib/apt/lists/*

RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@${XCADDY_VERSION}

# Expose for build.py provenance recording
ENV XCADDY_VERSION=${XCADDY_VERSION}

WORKDIR /build
COPY matrix.yaml build.py ./

CMD ["uv", "run", "build.py"]
