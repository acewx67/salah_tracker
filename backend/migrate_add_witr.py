"""
Migration: add isha_witr column to prayer_logs table.
Run once: python migrate_add_witr.py
"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from database import engine
from sqlalchemy import text

def run():
    with engine.connect() as conn:
        # Check if column already exists
        try:
            conn.execute(text("SELECT isha_witr FROM prayer_logs LIMIT 1"))
            print("Column 'isha_witr' already exists — skipping migration.")
        except Exception:
            conn.execute(text(
                "ALTER TABLE prayer_logs ADD COLUMN isha_witr INTEGER NOT NULL DEFAULT 0"
            ))
            conn.commit()
            print("Migration complete: added 'isha_witr' column to prayer_logs.")

if __name__ == "__main__":
    run()
