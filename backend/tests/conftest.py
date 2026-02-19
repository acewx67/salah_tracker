"""Pytest conftest — sets test DATABASE_URL before any app module is imported."""

import os
import tempfile

# MUST happen before anything imports database/config
_test_db_path = os.path.join(tempfile.gettempdir(), "salah_test.db")
os.environ["DATABASE_URL"] = f"sqlite:///{_test_db_path}"
