#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

: "${INSTALL_PACKAGES:?INSTALL_PACKAGES is required}"
: "${OPENWRT_RELEASE:?OPENWRT_RELEASE is required}"
: "${OPENWRT_ARCH:?OPENWRT_ARCH is required}"

_smoke_start=$SECONDS

SSH_PORT="${SSH_PORT:-2222}"
SSH_HOST="${SSH_HOST:-127.0.0.1}"
SSH_USER="${SSH_USER:-root}"
FEED_HOST="${FEED_HOST:-10.0.2.2}"
FEED_PORT="${FEED_PORT:-8080}"

PACKAGE_FORMAT="$(derive_package_format)"

if [[ -z "${FEED_URLS:-}" ]]; then
    FEED_URLS="http://${FEED_HOST}:${FEED_PORT}/${OPENWRT_RELEASE}/${OPENWRT_ARCH}"
fi

ssh_vm() {
    sshpass -p "" ssh \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=10 \
        -o BatchMode=no \
        -p "$SSH_PORT" "${SSH_USER}@${SSH_HOST}" \
        "$@"
}

# ── Configuration dump ──────────────────────────────────────────────────────
{
    echo "run_id=${RUN_ID}"
    echo "openwrt_version=${OPENWRT_VERSION:-}"
    echo "openwrt_release=${OPENWRT_RELEASE}"
    echo "openwrt_arch=${OPENWRT_ARCH}"
    echo "package_format=${PACKAGE_FORMAT}"
    echo "install_packages=${INSTALL_PACKAGES}"
    echo "github_workflow=${GITHUB_WORKFLOW:-}"
    echo "github_run_number=${GITHUB_RUN_NUMBER:-}"
    echo "github_sha=${GITHUB_SHA:-}"
    echo "github_ref_name=${GITHUB_REF_NAME:-}"
    i=1
    while IFS= read -r url; do
        [[ -z "$url" ]] && continue
        echo "feed_url_${i}=${url}"
        i=$((i+1))
    done <<< "$FEED_URLS"
} | tee /tmp/resolved-config.env | while IFS= read -r line; do log "config ${line}"; done

# ── Feed identity — index checksum ──────────────────────────────────────────
i=1
feeds_count=0
while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    case "$PACKAGE_FORMAT" in
      apk) idx_url="${url}/packages.adb" ;;
      ipk) idx_url="${url}/Packages.gz" ;;
    esac
    if sha=$(curl -fsS "$idx_url" 2>/dev/null | sha256sum | awk '{print $1}'); then
        log "feed[$i] url=${url} index_sha256=${sha}"
    else
        log "feed[$i] url=${url} status=unreachable"
    fi
    i=$((i+1))
    feeds_count=$((feeds_count+1))
done <<< "$FEED_URLS"

# ── Failure diagnostics trap ─────────────────────────────────────────────────
_fail_summary() {
    local rc=$?
    [[ "$rc" -eq 0 ]] && return
    log "test status=failed exit_code=${rc}"
    cat >&2 <<SUMMARY

==================== FAILURE SUMMARY ====================
Run ID:     ${RUN_ID}
Exit code:  ${rc}
Feed URLs:
$(printf '%s\n' "$FEED_URLS" | sed 's/^/  /')
=========================================================
SUMMARY
    echo "=== QEMU log (tail 100) ===" >&2
    tail -n 100 /tmp/qemu.log 2>/dev/null || true
    echo "=== Feed server log ===" >&2
    tail -n 50 /tmp/feed-stable.log 2>/dev/null || true
    ssh_vm "cat /etc/apk/repositories.d/harness.list 2>/dev/null \
         || cat /etc/opkg/harness.conf 2>/dev/null" 2>/dev/null || true
}
trap _fail_summary EXIT

# ── Configure repos and install ──────────────────────────────────────────────
# Official feeds are retained; harness entries take priority via filename ordering / opkg priority.
case "$PACKAGE_FORMAT" in
  apk)
    log "stage=install format=apk packages=${INSTALL_PACKAGES}"
    while IFS= read -r url; do
        [[ -z "$url" ]] && continue
        printf '%s/packages.adb\n' "$url"
    done <<< "$FEED_URLS" | ssh_vm "cat > /etc/apk/repositories.d/harness.list"
    # -U = --update: refresh index before install
    # shellcheck disable=SC2086
    ssh_vm "apk -U add ${INSTALL_PACKAGES}" 2>&1 | tee /tmp/package-install.log
    ;;
  ipk)
    log "stage=install format=ipk packages=${INSTALL_PACKAGES}"
    i=0
    {
        while IFS= read -r url; do
            [[ -z "$url" ]] && continue
            printf 'src/gz harness%d %s\n' "$i" "$url"
            i=$((i+1))
        done <<< "$FEED_URLS"
    } | ssh_vm "cat > /etc/opkg/harness.conf"
    ssh_vm "opkg update"
    # shellcheck disable=SC2086
    ssh_vm "opkg install ${INSTALL_PACKAGES}" 2>&1 | tee /tmp/package-install.log
    ;;
  *)
    echo "Unsupported PACKAGE_FORMAT: ${PACKAGE_FORMAT}" >&2; exit 2 ;;
esac

# ── Post-install version query ────────────────────────────────────────────────
# INSTALL_PACKAGES is space-separated (same tokens passed to apk/opkg).
packages_installed=0
for pkg in $INSTALL_PACKAGES; do
    case "$PACKAGE_FORMAT" in
      apk) version=$(ssh_vm "apk info ${pkg} 2>/dev/null | awk 'NR==1{print \$1}'" || echo unknown) ;;
      ipk) version=$(ssh_vm "opkg status ${pkg} 2>/dev/null | awk '/Version:/{print \$2}'" || echo unknown) ;;
    esac
    log "installed package=${pkg} version=${version}"
    packages_installed=$((packages_installed+1))
done

# ── Verification commands ─────────────────────────────────────────────────────
verify_total=0
verify_failed=0
if [[ -n "${VERIFY_COMMANDS:-}" ]]; then
    while IFS= read -r cmd; do
        [[ -z "$cmd" ]] && continue
        log "verify command=${cmd} status=start"
        if ssh_vm "$cmd" >> /tmp/package-install.log 2>&1; then
            log "verify command=${cmd} status=success"
        else
            log "verify command=${cmd} status=fail" >&2
            verify_failed=$((verify_failed+1))
        fi
        verify_total=$((verify_total+1))
    done <<< "$VERIFY_COMMANDS"
fi

packages_requested=0
for _p in $INSTALL_PACKAGES; do packages_requested=$((packages_requested+1)); done
log "metrics packages_requested=${packages_requested} packages_installed=${packages_installed} feeds_configured=${feeds_count} verify_commands=${verify_total} verify_failed=${verify_failed} test_duration_seconds=$((SECONDS - _smoke_start))"

[[ "$verify_failed" -eq 0 ]] || exit 1
log "test status=success"
