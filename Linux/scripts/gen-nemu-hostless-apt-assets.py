#!/usr/bin/env python3
"""Generate NEMU hostless APT repository C assets."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import os
import subprocess
import tarfile
import tempfile
from pathlib import Path


EPOCH = 1781222400
REPO_DATE = "Fri, 12 Jun 2026 00:00:00 UTC"
SIGN_EPOCH = 1781382400
HOSTLESS_APT_SIGNING_FINGERPRINT = "E6742789E6F3AAEAD748589209108C9EAFAA6C14"
HOSTLESS_APT_SIGNING_KEY_ASC = """-----BEGIN PGP PRIVATE KEY BLOCK-----

lQOYBGotuGoBCACg2yumcRT1fglok03Td8TjRwcetA5iQ9C9FChFrgOkhfsEu3/3
8bqF2TGRsFbtZLS/bM0nyQm1dX2JBppJPN6n80MMo10R5WKKXDWAOt++o+ZzfakT
2cyKjhYQ0j34Hoomk9QnEyLO30bec+DhwHQGoD63IPSrMcFcj8VvZoP6lzY+ob1u
HI0CB2kfYEBTywQEo2j62lmjrQroyJExr6ZUlfV25Z1sD2/0MuJFM2N1Hs6XZymd
G3Z5d7kUgbH+3n+qk1dJRGZ2w2UH+DNSVcniHenGn+j693PimNdavwjuyyItojb3
bJKE6RondZXQWcWiEPq6mXGmbqrp31DzsBvFABEBAAEAB/wPGJKPo8QyR9pNMKnY
o0BcjhFqfb5t1Wx1GjuvUmXwHkzRBGG9nLeDET+YKyL1U4KtBmJ4jeL13ylhXzfC
kM5al7deq8QzxkHJt16kAqJ16z7Y7t2bydBq3mvOt1RugTs45J2/7wlQvd6SSPC9
bwjUiFxqZlLf8CLz82A1lLrlHP64pwTzLImJv0TvknI1EvAYhddV0pBB6Tua5Lfe
nvzdLlhmOhU6inOzmrYpU5lq5cJ1X0t7AnG2lgqQFXqsdTZ/gby92kOwcrVJA3jB
qJ3nMz/Zna5OYV6v8vmTpRNy3C1d22nDdCrCrUeq+xx1KvRpOIOrzUnrA9QFS8Ch
ffpPBADJR2YhUDM316TKtOWKaasUQFX+mo4g6iKywzmKQwfsb1O5dHHuLlqjI6K0
zG3NWbs6zP9eJ/kLZsAYFwRkmhD3jq0WJLlIljhW1/o/xzf9tQKw0u/+HESKawdw
HW9BVKrUDKuPyWUcgTNrlC8jBKjiol93dE/lhwMohqYcKlAQHwQAzJZt7WXV/XnE
gfPhbHMj8jQP0efYlzA6TacN1x1R8UnKG6/E7wsbPnvYDIFLKf4JowTf7H5GFF81
h/hDmkX8a+EzpDNsWxhdCCns2qB5XWJl1DW9sqKb+Z/KHPAoYUaFmvEgn9wZDvae
IUbC3GwbtTo3yro6kypF8YPNeBSKh5sEAJBgFvy+Qn7StEDR8v3do0mwHJznNAMx
3YgjeqM+L+inJTYseV12W72ehsDyS8NDo1lRnJEEZpGSOit5NpN6z1IVuwWhBXYU
tlOiRUNniTmAsC5tMts3WXVECrA1pJ71R/B24zzVLtdCVCaDVn72THQlbkwWl6sR
QWAA7AtfliaeO/u0LU5FTVUgSG9zdGxlc3MgQXB0IFRlc3QgPG5lbXVAZXhhbXBs
ZS5pbnZhbGlkPokBUQQTAQoAOxYhBOZ0J4nm86rq10hYkgkQjJ6vqmwUBQJqLbhq
AhsDBQsJCAcCAiICBhUKCQgLAgQWAgMBAh4HAheAAAoJEAkQjJ6vqmwUGOoIAIKm
FCXlTZ+5g/wVqdDEr0unPFj+pAxU4NhuFIYapKing0csKuX2a8cjK1f6CVF3jQOs
CJ789oaUrtFul14doEEL2sWEDqZieZkQ+DB1SbaT9B4qpmCaeqVndBj2hgooJs4w
DPZnGenJkWOZi0FLEgUoOruLJ2z5iLnTV/f4eEs8HQFSmMHqAqV7mdflL65KKuCL
E2XrmAx1AUt0/dGpIaimRNWKnz7DgFjez6S/enY8v0uZ5TTPu/U9pmmYD514THri
0UN1cX3TIzME/HKAhnq39RfNhToeMXlfAPHHwBAQ/Zhd6OIQBmRcQeo/m5ekxohO
bqOmRTiheq7fTC0nKr0=
=n/aS
-----END PGP PRIVATE KEY BLOCK-----
"""


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def checked_dump_dir(path: Path, allow_repo_root_dump: bool) -> Path:
    resolved = path.expanduser().resolve(strict=False)
    if resolved == repo_root() and not allow_repo_root_dump:
        raise SystemExit(
            "refusing to dump hostless APT assets into the repository root; "
            "use --dump-dir /tmp/nemu-hostless-apt-assets or pass "
            "--allow-repo-root-dump for an intentional one-off debug dump"
        )
    return resolved


def gz_bytes(payload: bytes) -> bytes:
    out = io.BytesIO()
    with gzip.GzipFile(fileobj=out, mode="wb", compresslevel=9, mtime=0) as gz:
        gz.write(payload)
    return out.getvalue()


def run_gpg(homedir: Path, args: list[str], input_data: bytes | None = None) -> bytes:
    cmd = [
        "gpg",
        "--batch",
        "--yes",
        "--no-tty",
        "--homedir",
        str(homedir),
        "--pinentry-mode",
        "loopback",
        "--passphrase",
        "",
        *args,
    ]
    env = os.environ.copy()
    env["LC_ALL"] = "C"
    proc = subprocess.run(
        cmd,
        input=input_data,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
        check=False,
    )
    if proc.returncode != 0:
        raise SystemExit(
            f"gpg failed rc={proc.returncode}: {' '.join(cmd)}\n"
            f"{proc.stderr.decode('utf-8', errors='replace')}"
        )
    return proc.stdout


def sign_release(release_text: str) -> tuple[str, bytes]:
    with tempfile.TemporaryDirectory(prefix="nemu-hostless-apt-gpg-") as tmp:
        tmp_path = Path(tmp)
        homedir = tmp_path / "gnupg"
        homedir.mkdir(mode=0o700)
        secret_key = tmp_path / "hostless-test-secret.asc"
        secret_key.write_text(HOSTLESS_APT_SIGNING_KEY_ASC, encoding="ascii")
        run_gpg(homedir, ["--import", str(secret_key)])
        keyring = run_gpg(homedir, ["--export", HOSTLESS_APT_SIGNING_FINGERPRINT])
        inrelease = run_gpg(
            homedir,
            [
                "--faked-system-time",
                str(SIGN_EPOCH),
                "--local-user",
                HOSTLESS_APT_SIGNING_FINGERPRINT,
                "--digest-algo",
                "SHA256",
                "--clearsign",
            ],
            release_text.encode("utf-8"),
        ).decode("utf-8")
        return inrelease, keyring


def tar_gz(files: list[tuple[str, bytes, int]]) -> bytes:
    def add_entry(tf: tarfile.TarFile, name: str, data: bytes, mode: int, kind: bytes) -> None:
        info = tarfile.TarInfo(name)
        info.size = len(data)
        info.mode = mode
        info.uid = 0
        info.gid = 0
        info.uname = ""
        info.gname = ""
        info.mtime = 0
        info.type = kind
        tf.addfile(info, io.BytesIO(data))

    def parent_dirs(name: str) -> list[str]:
        if "/" not in name:
            return []
        prefix = "./" if name.startswith("./") else ""
        rel = name[2:] if name.startswith("./") else name
        parts = [part for part in rel.split("/")[:-1] if part]
        out = []
        current = prefix.rstrip("/")
        for part in parts:
            current = f"{current}/{part}" if current else part
            out.append(f"{current}/")
        return out

    out = io.BytesIO()
    with gzip.GzipFile(fileobj=out, mode="wb", compresslevel=9, mtime=0) as gz:
        with tarfile.open(fileobj=gz, mode="w", format=tarfile.USTAR_FORMAT) as tf:
            added_dirs = set()
            for name, data, mode in files:
                for dir_name in parent_dirs(name):
                    if dir_name not in added_dirs:
                        add_entry(tf, dir_name, b"", 0o755, tarfile.DIRTYPE)
                        added_dirs.add(dir_name)
                add_entry(tf, name, data, mode, tarfile.REGTYPE)
    return out.getvalue()


def ar_member(name: str, data: bytes) -> bytes:
    if len(name) > 15:
        name = f"{name}/"
    header = (
        f"{name:<16}"
        f"{EPOCH:<12}"
        f"{0:<6}"
        f"{0:<6}"
        f"{0o100644:<8}"
        f"{len(data):<10}`\n"
    ).encode("ascii")
    body = data
    if len(body) % 2:
        body += b"\n"
    return header + body


def build_deb(
    package: str,
    version: str,
    description: str,
    long_description: str,
    data_files: list[tuple[str, bytes]],
    depends: str | None = None,
    scripts: dict[str, str] | None = None,
) -> bytes:
    control_lines = [
        f"Package: {package}",
        f"Version: {version}",
        "Architecture: riscv64",
        "Maintainer: NEMU Hostless Apt <nemu@example.invalid>",
    ]
    if depends:
        control_lines.append(f"Depends: {depends}")
    control_lines.extend(
        [
            "Installed-Size: 1",
            "Section: base",
            "Priority: optional",
            f"Description: {description}",
            f" {long_description}",
            "",
        ]
    )
    control_files: list[tuple[str, bytes, int]] = [
        ("./control", "\n".join(control_lines).encode("utf-8"), 0o644)
    ]
    for script_name, script_body in (scripts or {}).items():
        control_files.append((f"./{script_name}", script_body.encode("utf-8"), 0o755))

    data_tar_files = [(path, data, 0o644) for path, data in data_files]
    control = tar_gz(control_files)
    data = tar_gz(data_tar_files)
    return (
        b"!<arch>\n"
        + ar_member("debian-binary", b"2.0\n")
        + ar_member("control.tar.gz", control)
        + ar_member("data.tar.gz", data)
    )


def meta_scripts(version_suffix: str = "") -> dict[str, str]:
    suffix = f" {version_suffix}" if version_suffix else ""
    return {
        name: (
            "#!/bin/sh\n"
            "set -e\n"
            "mkdir -p /var/lib/nemu-hostless-meta\n"
            f"printf '%s\\n' '{name} from NEMU hostless meta{suffix}' "
            f">/var/lib/nemu-hostless-meta/{name}-message\n"
            "exit 0\n"
        )
        for name in ("preinst", "postinst", "prerm", "postrm")
    }


def package_set() -> list[dict[str, object]]:
    hello_10 = build_deb(
        "nemu-hostless-hello",
        "1.0",
        "NEMU hostless apt install smoke package",
        "This package proves that NEMU hostless APT can fetch and install a real deb.",
        [("./usr/share/nemu-hostless-hello/message", b"hello from NEMU hostless apt\n")],
    )
    meta_10 = build_deb(
        "nemu-hostless-meta",
        "1.0",
        "NEMU hostless apt dependency smoke package",
        "This package depends on nemu-hostless-hello to prove apt dependency install.",
        [("./usr/share/nemu-hostless-meta/message", b"hello from NEMU hostless meta\n")],
        depends="nemu-hostless-hello (= 1.0)",
        scripts=meta_scripts(),
    )
    hello_11 = build_deb(
        "nemu-hostless-hello",
        "1.1",
        "NEMU hostless apt upgrade smoke package",
        "This package proves that NEMU hostless APT can upgrade a real deb.",
        [("./usr/share/nemu-hostless-hello/message", b"hello from NEMU hostless apt v1.1\n")],
    )
    meta_11 = build_deb(
        "nemu-hostless-meta",
        "1.1",
        "NEMU hostless apt upgrade dependency smoke package",
        "This package depends on the upgraded hello package to prove apt upgrade.",
        [("./usr/share/nemu-hostless-meta/message", b"hello from NEMU hostless meta v1.1\n")],
        depends="nemu-hostless-hello (= 1.1)",
        scripts=meta_scripts("v1.1"),
    )
    return [
        {
            "package": "nemu-hostless-hello",
            "version": "1.1",
            "filename": "pool/main/n/nemu-hostless-hello/nemu-hostless-hello_1.1_riscv64.deb",
            "deb": hello_11,
            "description": "NEMU hostless apt upgrade smoke package",
            "long": "This package proves that NEMU hostless APT can upgrade a real deb.",
        },
        {
            "package": "nemu-hostless-meta",
            "version": "1.1",
            "filename": "pool/main/n/nemu-hostless-meta/nemu-hostless-meta_1.1_riscv64.deb",
            "deb": meta_11,
            "depends": "nemu-hostless-hello (= 1.1)",
            "description": "NEMU hostless apt upgrade dependency smoke package",
            "long": "This package depends on the upgraded hello package to prove apt upgrade.",
        },
        {
            "package": "nemu-hostless-hello",
            "version": "1.0",
            "filename": "pool/main/n/nemu-hostless-hello/nemu-hostless-hello_1.0_riscv64.deb",
            "deb": hello_10,
            "description": "NEMU hostless apt install smoke package",
            "long": "This package proves that NEMU hostless APT can fetch and install a real deb.",
        },
        {
            "package": "nemu-hostless-meta",
            "version": "1.0",
            "filename": "pool/main/n/nemu-hostless-meta/nemu-hostless-meta_1.0_riscv64.deb",
            "deb": meta_10,
            "depends": "nemu-hostless-hello (= 1.0)",
            "description": "NEMU hostless apt dependency smoke package",
            "long": "This package depends on nemu-hostless-hello to prove apt dependency install.",
        },
    ]


def stanza(pkg: dict[str, object]) -> str:
    deb = pkg["deb"]
    assert isinstance(deb, bytes)
    lines = [
        f"Package: {pkg['package']}",
        f"Version: {pkg['version']}",
        "Architecture: riscv64",
        "Maintainer: NEMU Hostless Apt <nemu@example.invalid>",
    ]
    depends = pkg.get("depends")
    if depends:
        lines.append(f"Depends: {depends}")
    lines.extend(
        [
            "Installed-Size: 1",
            f"Filename: {pkg['filename']}",
            f"Size: {len(deb)}",
            f"MD5sum: {hashlib.md5(deb).hexdigest()}",
            f"SHA256: {hashlib.sha256(deb).hexdigest()}",
            "Section: base",
            "Priority: optional",
            f"Description: {pkg['description']}",
            f" {pkg['long']}",
            "",
        ]
    )
    return "\n".join(lines) + "\n"


def release_stanza(packages_bytes: bytes, packages_gz: bytes) -> str:
    return (
        "Suite: jammy\n"
        "Codename: jammy\n"
        "Components: main\n"
        "Architectures: riscv64\n"
        f"Date: {REPO_DATE}\n"
        "MD5Sum:\n"
        f" {hashlib.md5(packages_bytes).hexdigest()} {len(packages_bytes)} main/binary-riscv64/Packages\n"
        f" {hashlib.md5(packages_gz).hexdigest()} {len(packages_gz)} main/binary-riscv64/Packages.gz\n"
        "SHA256:\n"
        f" {hashlib.sha256(packages_bytes).hexdigest()} {len(packages_bytes)} main/binary-riscv64/Packages\n"
        f" {hashlib.sha256(packages_gz).hexdigest()} {len(packages_gz)} main/binary-riscv64/Packages.gz\n"
    )


def c_string_lines(text: str, indent: str = "    ") -> str:
    out = []
    for line in text.splitlines(True):
        escaped = line.encode("unicode_escape").decode("ascii")
        escaped = escaped.replace('"', r'\"')
        out.append(f'{indent}"{escaped}"')
    return "\n".join(out)


def c_byte_lines(data: bytes, indent: str = "    ") -> str:
    chunks = []
    escaped = "".join(f"\\{b:03o}" for b in data)
    for i in range(0, len(escaped), 76):
        chunks.append(f'{indent}"{escaped[i:i + 76]}"')
    return "\n".join(chunks)


def emit_assets() -> tuple[str, dict[str, str]]:
    pkgs = package_set()
    packages_text = "".join(stanza(pkg) for pkg in pkgs)
    packages_bytes = packages_text.encode("utf-8")
    packages_gz = gz_bytes(packages_bytes)
    release_text = release_stanza(packages_bytes, packages_gz)
    inrelease_text, keyring_bytes = sign_release(release_text)
    deb_map = {f"{pkg['package']}_{pkg['version']}": pkg["deb"] for pkg in pkgs}
    hashes = {
        "inrelease_sha256": hashlib.sha256(inrelease_text.encode("utf-8")).hexdigest(),
        "keyring_sha256": hashlib.sha256(keyring_bytes).hexdigest(),
        "hello_1_0_sha256": hashlib.sha256(deb_map["nemu-hostless-hello_1.0"]).hexdigest(),
        "meta_1_0_sha256": hashlib.sha256(deb_map["nemu-hostless-meta_1.0"]).hexdigest(),
        "hello_1_1_sha256": hashlib.sha256(deb_map["nemu-hostless-hello_1.1"]).hexdigest(),
        "meta_1_1_sha256": hashlib.sha256(deb_map["nemu-hostless-meta_1.1"]).hexdigest(),
        "inrelease_size": str(len(inrelease_text.encode("utf-8"))),
        "keyring_size": str(len(keyring_bytes)),
        "hello_1_0_size": str(len(deb_map["nemu-hostless-hello_1.0"])),
        "meta_1_0_size": str(len(deb_map["nemu-hostless-meta_1.0"])),
        "hello_1_1_size": str(len(deb_map["nemu-hostless-hello_1.1"])),
        "meta_1_1_size": str(len(deb_map["nemu-hostless-meta_1.1"])),
    }
    block = f'''  static const uint8_t nemu_apt_release[] =
{c_string_lines(release_text)};
  static const uint8_t nemu_apt_inrelease[] =
{c_string_lines(inrelease_text)};
  static const uint8_t nemu_apt_keyring[] =
{c_byte_lines(keyring_bytes)};
  static const uint8_t nemu_apt_packages[] =
{c_string_lines(packages_text)};
  static const uint8_t nemu_apt_packages_gz[] =
{c_byte_lines(packages_gz)};
  static const uint8_t nemu_apt_hello_v1_0_deb[] =
{c_byte_lines(deb_map["nemu-hostless-hello_1.0"])};
  static const uint8_t nemu_apt_meta_v1_0_deb[] =
{c_byte_lines(deb_map["nemu-hostless-meta_1.0"])};
  static const uint8_t nemu_apt_hello_v1_1_deb[] =
{c_byte_lines(deb_map["nemu-hostless-hello_1.1"])};
  static const uint8_t nemu_apt_meta_v1_1_deb[] =
{c_byte_lines(deb_map["nemu-hostless-meta_1.1"])};
'''
    return block, hashes


def update_net_c(path: Path) -> dict[str, str]:
    block, hashes = emit_assets()
    text = path.read_text()
    start = text.index("  static const uint8_t nemu_apt_release[] =\n")
    end = text.index("  static const char http_get_prefix[] =", start)
    path.write_text(text[:start] + block + text[end:])
    return hashes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--update-net-c", type=Path)
    parser.add_argument(
        "--dump-dir",
        type=Path,
        help="write deb/Packages debug assets to this directory; repo root is refused by default",
    )
    parser.add_argument(
        "--allow-repo-root-dump",
        action="store_true",
        help="allow --dump-dir to be the repository root for an intentional debug run",
    )
    parser.add_argument("--print-hashes", action="store_true")
    args = parser.parse_args()

    if args.update_net_c:
        hashes = update_net_c(args.update_net_c)
    else:
        _, hashes = emit_assets()
    if args.dump_dir:
        dump_dir = checked_dump_dir(args.dump_dir, args.allow_repo_root_dump)
        dump_dir.mkdir(parents=True, exist_ok=True)
        pkgs = package_set()
        packages_text = "".join(stanza(pkg) for pkg in pkgs)
        packages_bytes = packages_text.encode("utf-8")
        packages_gz = gz_bytes(packages_bytes)
        release_text = release_stanza(packages_bytes, packages_gz)
        inrelease_text, keyring_bytes = sign_release(release_text)
        (dump_dir / "Release").write_text(release_text)
        (dump_dir / "InRelease").write_text(inrelease_text)
        (dump_dir / "nemu-hostless-archive-keyring.gpg").write_bytes(keyring_bytes)
        (dump_dir / "Packages").write_text(packages_text)
        (dump_dir / "Packages.gz").write_bytes(packages_gz)
        for pkg in pkgs:
            filename = str(pkg["filename"]).split("/")[-1]
            deb = pkg["deb"]
            assert isinstance(deb, bytes)
            (dump_dir / filename).write_bytes(deb)
    if args.print_hashes:
        for key in sorted(hashes):
            print(f"{key}={hashes[key]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
