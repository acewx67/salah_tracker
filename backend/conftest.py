"""Root conftest — sets test DATABASE_URL before any module is imported."""

import os
import tempfile

_test_db_path = os.path.join(tempfile.gettempdir(), "salah_test.db")
os.environ["DATABASE_URL"] = f"sqlite:///{_test_db_path}"
