#!/usr/bin/env python3
"""Exercise launch-agent paths with a built binary and isolated synthetic files."""

import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile


def main():
    binary = Path(sys.argv[1]).resolve(strict=True)
    with tempfile.TemporaryDirectory(prefix="swabble service-") as temporary:
        root = Path(temporary).resolve()
        agents = root / "agents"
        env = dict(os.environ, SWABBLE_LAUNCH_AGENTS_DIR=str(agents))
        plist = agents / "com.swabble.agent.plist"
        old_binary = root / "v1" / "swabble"
        new_binary = root / "v2" / "swabble"
        link = root / "bin" / "swabble"
        for path in (old_binary, new_binary, link):
            path.parent.mkdir()
        shutil.copy2(binary, old_binary)
        shutil.copy2(binary, new_binary)
        link.symlink_to(old_binary)

        def run(arguments, **kwargs):
            kwargs.setdefault("cwd", root)
            return subprocess.run(
                arguments, env=env, check=True,
                text=True, capture_output=True, **kwargs,
            ).stdout.strip()

        def installed_path():
            with plist.open("rb") as stream:
                arguments = plistlib.load(stream)["ProgramArguments"]
            assert arguments[1:] == ["serve"], arguments
            stored = Path(arguments[0])
            assert stored.is_absolute(), stored
            assert stored.is_symlink(), stored
            # Foundation can canonicalize macOS's /private/var alias to /var.
            assert stored.parent.samefile(link.parent) and stored.name == link.name, stored
            return str(stored)

        # PATH launches can pass a bare argv[0] despite executing an absolute path.
        for argv0 in ("swabble", "bin/swabble", str(link)):
            run([argv0, "service", "install"], executable=str(link))
            installed_path()
            print(f"PASS: service install through {argv0}")

        # Parent-directory components must not cause the link to be resolved.
        stored_paths = []
        for executable in ("bin/swabble", "bin/../bin/swabble"):
            run([executable, "service", "install"])
            stored_paths.append(installed_path())
        run(["../bin/swabble", "service", "install"], cwd=old_binary.parent)
        stored_paths.append(installed_path())
        link.unlink()
        link.symlink_to(new_binary)
        old_binary.unlink()
        for stored in stored_paths:
            assert run([stored, "health"], cwd="/") == "ok"
        assert run([stored, "service", "status"]) == f"plist present at {plist}"
        print("PASS: stored path survives retargeting the symlink and deleting the old binary")

        run([stored, "service", "uninstall"])
        assert not plist.exists()
        run([stored, "service", "uninstall"])
        assert run([stored, "service", "status"]) == "launchd plist not installed"
        print("PASS: service uninstall and status use the isolated agents directory")


if __name__ == "__main__":
    main()
