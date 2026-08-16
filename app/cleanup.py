from __future__ import annotations

import gc
import os
import shutil
import time
from pathlib import Path


class SessionCleaner:
    """Owns deletion of participant-session data.

    All participant-generated or participant-derived files must live below
    session_root. Nothing outside session_root is deleted by this class.
    """

    def __init__(self, session_root: Path):
        self.session_root = session_root.resolve()
        self.session_root.mkdir(parents=True, exist_ok=True)

    def _assert_below_root(self, path: Path) -> Path:
        resolved = path.resolve()
        if resolved == self.session_root:
            return resolved
        if self.session_root not in resolved.parents:
            raise ValueError(f"Refusing to delete path outside session root: {resolved}")
        return resolved

    def delete_session(self, session_dir: Path) -> None:
        """Delete an entire participant session directory.

        This is the primary cleanup operation. Because final deployment uses
        a RAM-backed tmpfs, unlinking these files removes the live session data
        without depending on SSD overwrite semantics.
        """
        session_dir = self._assert_below_root(session_dir)

        if session_dir == self.session_root:
            raise ValueError("delete_session may not delete the session root")

        if session_dir.exists():
            shutil.rmtree(session_dir, ignore_errors=False)

        gc.collect()

    def clear_all_sessions(self) -> int:
        """Remove all participant session directories.

        Returns the number of top-level session entries removed.
        """
        removed = 0
        self.session_root.mkdir(parents=True, exist_ok=True)

        for child in list(self.session_root.iterdir()):
            self._assert_below_root(child)
            if child.is_dir():
                shutil.rmtree(child, ignore_errors=False)
            else:
                child.unlink(missing_ok=True)
            removed += 1

        gc.collect()
        return removed

    def clear_stale_sessions(self, max_age_seconds: int = 3600) -> int:
        """Remove abandoned sessions older than max_age_seconds."""
        now = time.time()
        removed = 0

        for child in list(self.session_root.iterdir()):
            self._assert_below_root(child)
            try:
                age = now - child.stat().st_mtime
            except FileNotFoundError:
                continue

            if age >= max_age_seconds:
                if child.is_dir():
                    shutil.rmtree(child, ignore_errors=False)
                else:
                    child.unlink(missing_ok=True)
                removed += 1

        gc.collect()
        return removed
