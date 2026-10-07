from pathlib import Path
import subprocess
import tempfile
import unittest

WRAPPER = Path(__file__).resolve().parents[1] / "run-nemu-reboot-loop.sh"

class RebootLoopTest(unittest.TestCase):
    def run_loop(self, budget, terminal):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            count = root / "count"
            child = root / "child.py"
            child.write_text(
                "from pathlib import Path\nimport sys\n"
                "p=Path(sys.argv[1]); n=int(p.read_text())+1 if p.exists() else 1\n"
                "p.write_text(str(n))\n"
                "sys.exit(32 if n < 3 else int(sys.argv[2]))\n"
            )
            result = subprocess.run(
                ["bash", str(WRAPPER), f"--max-boots={budget}", "--",
                 "python3", str(child), str(count), str(terminal)],
                capture_output=True, text=True, timeout=10)
            return result, int(count.read_text())

    def test_unlimited_reboot_stops_on_poweroff(self):
        result, count = self.run_loop(0, 0)
        self.assertEqual((result.returncode, count), (0, 3))
        self.assertIn("reboot 2/unlimited", result.stderr)

    def test_finite_budget_stops_at_limit(self):
        result, count = self.run_loop(2, 0)
        self.assertEqual((result.returncode, count), (32, 2))
        self.assertIn("reboot limit reached", result.stderr)

    def test_unlimited_does_not_retry_other_errors(self):
        result, count = self.run_loop(0, 7)
        self.assertEqual((result.returncode, count), (7, 3))

if __name__ == "__main__":
    unittest.main()
