FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      qemu-system-x86 \
      qemu-utils \
      curl \
      gzip \
      openssh-client \
      netcat-openbsd \
      ca-certificates \
      python3 \
      sshpass \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /harness
COPY . .

CMD ["./run.sh"]
