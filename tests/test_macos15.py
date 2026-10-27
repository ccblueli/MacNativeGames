"""Exercise the Metal 3 buffer registry on a real Metal device; no game data needed."""
import platform
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
NVN = ROOT / 'games/totk/third_party/d2r_gfx/gfx/nvn'


class Metal3Registry(unittest.TestCase):
    @unittest.skipUnless(platform.system() == 'Darwin' and shutil.which('xcrun'), 'requires Metal SDK')
    def test_large_scene_buffers_remain_bindable(self):
        with tempfile.TemporaryDirectory() as folder:
            binary = Path(folder) / 'registry-probe'
            build = subprocess.run([
                'xcrun', 'clang', '-O2', '-fobjc-arc', '-DDM_NVN_M3=1', '-mmacosx-version-min=15.0',
                '-I' + str(NVN), str(ROOT / 'tests/m3_buffer_registry.m'), str(NVN / 'm3_compat.m'),
                '-framework', 'Metal', '-framework', 'Foundation', '-o', str(binary),
            ], capture_output=True, text=True)
            self.assertEqual(build.returncode, 0, build.stderr)
            result = subprocess.run([str(binary)], capture_output=True, text=True, timeout=30)
            if result.returncode == 77:
                self.skipTest('Metal device unavailable in this execution environment')
            self.assertEqual(result.returncode, 0, result.stderr)
