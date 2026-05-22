FROM alpine:latest AS builder

FROM n8nio/n8n:latest
USER root

# Copy apk tooling from a clean Alpine image so we can install packages
# in the n8n image regardless of its internal apk state.
COPY --from=builder /sbin/apk /sbin/apk
COPY --from=builder /etc/apk /etc/apk
COPY --from=builder /lib /lib
COPY --from=builder /usr/lib /usr/lib

# Install Docker CLI (DooD — lets n8n run docker commands via the host socket)
# and curl + unzip so we can fetch the rclone binary below.
RUN apk add --no-cache docker-cli curl unzip

# Install rclone — official binary, arch-aware (amd64 / arm64).
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
 && curl -fsSL "https://downloads.rclone.org/rclone-current-linux-${ARCH}.zip" \
         -o /tmp/rclone.zip \
 && unzip -q /tmp/rclone.zip -d /tmp/rclone-dl \
 && mv /tmp/rclone-dl/*/rclone /usr/local/bin/rclone \
 && chmod 755 /usr/local/bin/rclone \
 && rm -rf /tmp/rclone.zip /tmp/rclone-dl

# Add node user to the docker group so DooD works without running as root.
# GID 998 matches the typical Docker Desktop / Linux docker group — adjust if
# your host uses a different GID (check with: getent group docker).
RUN addgroup -g 998 docker 2>/dev/null || true \
 && adduser node docker 2>/dev/null || true

USER node
