# /// script
# dependencies = ["pyyaml"]
# ///
"""Stage 1 gap-fill build: Caddy tarballs for architectures not covered by
official Caddy upstream releases.

Upstream Caddy (github.com/caddyserver/caddy) covers amd64, arm64, armv5/v6/v7,
riscv64, s390x, ppc64le. This builder produces the remainder: mips, mipsle,
mips64, mips64le, loong64, 386.

Output per (caddy_version, go_target):
  dist/<version>/caddy_<version>_<goos>_<arch>.tar.gz   ← artifact (matches upstream format)
  dist/<version>/SHA256SUMS                              ← hashes of .tar.gz files
  dist/<version>/BUILD.json                              ← provenance

Tarball contents (flat, matching upstream Caddy release structure):
  caddy   ← statically-linked ELF binary

SHA256SUMS and BUILD.json are written only when all targets for a version succeed.

BUILD.json records two distinct layers of plugin information:
  requested_plugins  — strings from matrix.yaml (may lack @version for unpinned entries)
  resolved_modules   — actual versions embedded in the binary via `go version -m`

Use resolved_modules to pin floating entries after the first successful build, then
rebuild with explicit pins in matrix.yaml so both layers match.

Publishing to GitHub Releases is a separate step.
"""
import datetime
import hashlib
import json
import os
import subprocess
import sys
import tarfile
from pathlib import Path
from typing import Optional

import yaml

MATRIX_FILE = Path(__file__).parent / "matrix.yaml"
DIST_DIR = Path(os.environ.get("DIST_DIR", "/dist"))

# ELF markers expected in `file` output per Go binary suffix.
ELF_ARCH_MARKERS: dict[str, tuple[str, ...]] = {
    "386":            ("80386",),
    "amd64":          ("x86-64",),
    "arm64":          ("aarch64",),
    "arm":            ("ARM", "32-bit"),
    "loong64":        ("LoongArch",),
    "mips":           ("MIPS", "MSB"),
    "mips_softfloat": ("MIPS", "MSB"),
    "mips64":         ("MIPS", "64-bit", "MSB"),
    "mips64le":       ("MIPS", "64-bit", "LSB"),
    "mipsle":         ("MIPS", "LSB"),
}


def binary_suffix(target: dict) -> str:
    """Suffix used in ELF_ARCH_MARKERS lookup."""
    goarch = target["goarch"]
    if goarch == "arm" and "goarm" in target:
        return "arm"
    if goarch == "mips" and target.get("gomips") == "softfloat":
        return "mips_softfloat"
    return goarch


def artifact_name(version: str, target: dict) -> str:
    """Base name (without extension) for the output tarball.

    Matches upstream Caddy naming: caddy_<version>_<goos>_<arch>
    where arch for armv7 is 'armv7', not 'arm'.
    """
    suffix = binary_suffix(target)
    if suffix == "arm":
        display = f"armv{target['goarm']}"
    elif suffix == "mips_softfloat":
        display = "mips_softfloat"
    else:
        display = suffix
    return f"caddy_{version}_{target['goos']}_{display}"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def go_version() -> str:
    try:
        out = subprocess.check_output(["go", "version"], text=True).strip()
        return out.split()[2]  # "go version go1.23.4 linux/amd64" → "go1.23.4"
    except Exception:
        return "unknown"


def resolve_modules(binary_path: Path, requested_plugins: list[str]) -> dict[str, str]:
    """Extract resolved module versions from a Go binary's embedded build info.

    `go version -m` reads the .go.buildinfo ELF section — it does not execute
    the binary, so cross-compiled targets work fine on the build host.

    Returns a dict mapping module_path → resolved_version for each requested
    plugin. Plugins that appear in the binary are included; others are omitted.
    Pinned entries (github.com/foo@v1.2.3) will show their locked version.
    Unpinned entries will show whatever Go resolved at build time.
    """
    try:
        result = subprocess.run(
            ["go", "version", "-m", str(binary_path)],
            capture_output=True, text=True, check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return {}

    # Parse tab-separated dep lines: \tdep\t<module>\t<version>\t<hash>
    embedded: dict[str, str] = {}
    for line in result.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) >= 4 and parts[1] == "dep":
            embedded[parts[2]] = parts[3]

    # Match each requested plugin (strip @version to get module path).
    resolved: dict[str, str] = {}
    for plugin in requested_plugins:
        module = plugin.split("@")[0]
        if module in embedded:
            resolved[module] = embedded[module]

    return resolved


def verify_binary(path: Path, target: dict) -> bool:
    """Check that the binary is a statically-linked ELF for the expected arch."""
    try:
        result = subprocess.run(
            ["file", str(path)], capture_output=True, text=True, check=True
        )
        info = result.stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        print(f"  VERIFY FAILED: could not run 'file' on {path.name}", file=sys.stderr)
        return False

    if "ELF" not in info:
        print(f"  VERIFY FAILED: not an ELF — {info.strip()}", file=sys.stderr)
        return False

    if "statically linked" not in info:
        print(f"  VERIFY FAILED: not statically linked — {info.strip()}", file=sys.stderr)
        return False

    for marker in ELF_ARCH_MARKERS.get(binary_suffix(target), ()):
        if marker not in info:
            print(
                f"  VERIFY FAILED: missing '{marker}' in file output — {info.strip()}",
                file=sys.stderr,
            )
            return False

    return True


def create_tarball(binary_path: Path, tarball_path: Path) -> None:
    """Wrap binary as 'caddy' in a flat tarball matching upstream Caddy structure."""
    tmp = tarball_path.with_suffix(".tar.gz.tmp")
    try:
        with tarfile.open(tmp, "w:gz") as tf:
            tf.add(binary_path, arcname="caddy")
        tmp.rename(tarball_path)
    except Exception:
        tmp.unlink(missing_ok=True)
        raise


def build_cell(
    version: str,
    target: dict,
    plugins: list[str],
    out_dir: Path,
) -> Optional[dict[str, str]]:
    """Build one (version, target) cell.

    Returns a dict of resolved module versions on success (may be empty if
    `go version -m` is unavailable), or None on build/verify failure.
    """
    name = artifact_name(version, target)
    tarball_path = out_dir / f"{name}.tar.gz"
    bin_tmp = out_dir / f"{name}.tmp"

    bin_tmp.unlink(missing_ok=True)

    env = os.environ.copy()
    env["GOOS"] = target["goos"]
    env["GOARCH"] = target["goarch"]
    env["CGO_ENABLED"] = "0"
    if "goarm" in target:
        env["GOARM"] = str(target["goarm"])
    if "gomips" in target:
        env["GOMIPS"] = target["gomips"]

    cmd = ["xcaddy", "build", f"v{version}"]
    for plugin in plugins:
        cmd += ["--with", plugin]
    cmd += ["--output", str(bin_tmp)]

    print(f"  building {name} ...", flush=True)
    result = subprocess.run(cmd, env=env)
    if result.returncode != 0:
        bin_tmp.unlink(missing_ok=True)
        print(f"  FAILED: {name}", file=sys.stderr)
        return None

    if not verify_binary(bin_tmp, target):
        bin_tmp.unlink(missing_ok=True)
        return None

    # Extract resolved module versions before the binary is packed and discarded.
    resolved = resolve_modules(bin_tmp, plugins)

    create_tarball(bin_tmp, tarball_path)
    bin_tmp.unlink(missing_ok=True)  # tarball is the artifact; binary is intermediate

    digest = sha256_file(tarball_path)
    print(f"  ok  {digest}  {name}.tar.gz")
    return resolved


def write_sha256sums(version: str, out_dir: Path) -> None:
    lines = []
    for path in sorted(out_dir.glob(f"caddy_{version}_*.tar.gz")):
        lines.append(f"{sha256_file(path)}  {path.name}")
    (out_dir / "SHA256SUMS").write_text("\n".join(lines) + "\n")
    print("  wrote SHA256SUMS")


def write_build_json(
    version: str,
    requested_plugins: list[str],
    resolved_modules: dict[str, str],
    targets: list,
    out_dir: Path,
) -> None:
    provenance = {
        # Identity fields: together with SHA256 these define what was built.
        "caddy_version": version,
        "xcaddy_version": os.environ.get("XCADDY_VERSION", "unknown"),
        "go_version": go_version(),
        # requested_plugins: strings from matrix.yaml; may lack @version for
        # floating entries. After a successful build, compare with resolved_modules
        # and pin any floating entries before the next release build.
        "requested_plugins": requested_plugins,
        # resolved_modules: actual versions embedded in the binary by Go.
        # These are the ground truth for what was compiled in.
        "resolved_modules": resolved_modules,
        "targets": targets,
        # Audit field: useful for traceability but not part of artifact identity.
        "built_at": datetime.datetime.utcnow().isoformat() + "Z",
    }
    (out_dir / "BUILD.json").write_text(json.dumps(provenance, indent=2) + "\n")
    print("  wrote BUILD.json")


def main() -> None:
    matrix = yaml.safe_load(MATRIX_FILE.read_text())
    versions_config: dict = matrix["caddy"]["versions"]
    targets: list = matrix["targets"]

    failures: list[tuple[str, dict]] = []

    for version, ver_config in versions_config.items():
        plugins: list[str] = ver_config.get("plugins", [])
        print(f"\ncaddy {version}", flush=True)
        out_dir = DIST_DIR / version
        out_dir.mkdir(parents=True, exist_ok=True)

        version_failures: list[dict] = []
        # Collect resolved modules from the first successful build; all targets
        # share the same module graph for a given Caddy version + plugin set.
        version_resolved: dict[str, str] = {}

        for target in targets:
            resolved = build_cell(version, target, plugins, out_dir)
            if resolved is None:
                version_failures.append(target)
                failures.append((version, target))
            else:
                if not version_resolved:
                    version_resolved = resolved

        if version_failures:
            print(
                f"  skipping SHA256SUMS and BUILD.json — {len(version_failures)} target(s) failed",
                file=sys.stderr,
            )
        else:
            write_sha256sums(version, out_dir)
            write_build_json(version, plugins, version_resolved, targets, out_dir)

    if failures:
        print("\nFailed cells:", file=sys.stderr)
        for v, t in failures:
            print(f"  caddy {v} / {t}", file=sys.stderr)
        sys.exit(1)

    print("\nDone.")


if __name__ == "__main__":
    main()
