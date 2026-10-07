#!/usr/bin/env python3
import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location(
    "reuse_apt_archives", Path(__file__).resolve().parents[1] / "reuse-apt-archives.py"
)
cache = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cache)


class PackageReuseTest(unittest.TestCase):
    def test_cleaned_cache_restores_only_selected_verified_packages(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            saved, active = root / "packages", root / "archives"
            saved.mkdir()
            active.mkdir()
            for name, data in (("needed.deb", b"needed"), ("removed.deb", b"removed"),
                               ("corrupt.deb", b"broken")):
                (active / name).write_bytes(data)
            self.assertEqual(cache.save(saved, active), 3)
            for path in active.iterdir():
                path.unlink()
            digest = hashlib.sha256(b"needed").hexdigest()
            manifest = [
                "Reading package lists...\n",
                f"'https://mirror/needed.deb' needed.deb 6 SHA256:{digest}\n",
                f"'https://mirror/corrupt.deb' corrupt.deb 6 SHA256:{digest}\n",
            ]
            self.assertEqual(cache.restore(saved, active, manifest), 1)
            self.assertEqual(sorted(p.name for p in active.iterdir()), ["needed.deb"])
            self.assertEqual((active / "needed.deb").read_bytes(), b"needed")

    def test_manifest_cannot_escape_archive_directory(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with self.assertRaises(ValueError):
                cache.restore(root, root, ["'https://mirror/a' ../outside.deb 1 MD5Sum:0"])

    def test_saved_symlink_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "bad.deb").symlink_to(root / "outside")
            with self.assertRaises(ValueError):
                cache.restore(root, root, ["'https://mirror/a' bad.deb 1 MD5Sum:0"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
