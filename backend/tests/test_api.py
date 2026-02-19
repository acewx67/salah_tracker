"""Tests for API endpoints using a fully isolated in-memory test database."""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from sqlalchemy import create_engine, StaticPool
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient
from database import Base, get_db
from main import app

# In-memory SQLite with StaticPool to share across threads
test_engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


def override_get_db():
    db = TestSessionLocal()
    try:
        yield db
    finally:
        db.close()


# Override the dependency
app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def setup_db():
    """Create tables before each test and drop after."""
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def client():
    with TestClient(app, raise_server_exceptions=False) as c:
        yield c


class TestHealthEndpoints:
    def test_root(self, client):
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["app"] == "Salah Tracker API"

    def test_health(self, client):
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"


class TestAuthEndpoints:
    def test_google_login_mock(self, client):
        """In mock mode, any token should work."""
        response = client.post("/auth/google-login", json={"id_token": "mock_token"})
        assert response.status_code == 200
        data = response.json()
        assert "id" in data
        assert data["email"] == "dev@salahtracker.test"

    def test_get_me(self, client):
        """Get current user in mock mode."""
        client.post("/auth/google-login", json={"id_token": "mock"})
        response = client.get("/auth/me")
        assert response.status_code == 200


class TestPrayerLogEndpoints:
    def _login(self, client):
        client.post("/auth/google-login", json={"id_token": "mock"})

    def test_create_log(self, client):
        self._login(client)
        response = client.post("/logs/", json={
            "date": "2026-02-19",
            "fajr_fardh": True, "fajr_sunnah": 2, "fajr_nafl": 0,
            "dhuhr_fardh": True, "dhuhr_sunnah": 4, "dhuhr_nafl": 0,
            "asr_fardh": True, "asr_sunnah": 0, "asr_nafl": 0,
            "maghrib_fardh": True, "maghrib_sunnah": 2, "maghrib_nafl": 0,
            "isha_fardh": True, "isha_sunnah": 4, "isha_nafl": 0,
        })
        assert response.status_code == 201
        data = response.json()
        assert data["fajr_fardh"] is True
        assert data["daily_score"] > 0

    def test_get_log(self, client):
        self._login(client)
        client.post("/logs/", json={
            "date": "2026-02-19",
            "fajr_fardh": True, "fajr_sunnah": 0, "fajr_nafl": 0,
            "dhuhr_fardh": False, "dhuhr_sunnah": 0, "dhuhr_nafl": 0,
            "asr_fardh": False, "asr_sunnah": 0, "asr_nafl": 0,
            "maghrib_fardh": False, "maghrib_sunnah": 0, "maghrib_nafl": 0,
            "isha_fardh": False, "isha_sunnah": 0, "isha_nafl": 0,
        })
        response = client.get("/logs/2026-02-19")
        assert response.status_code == 200

    def test_get_log_not_found(self, client):
        self._login(client)
        response = client.get("/logs/2020-01-01")
        assert response.status_code == 404

    def test_upsert_overwrites(self, client):
        self._login(client)
        client.post("/logs/", json={
            "date": "2026-02-19",
            "fajr_fardh": False, "fajr_sunnah": 0, "fajr_nafl": 0,
            "dhuhr_fardh": False, "dhuhr_sunnah": 0, "dhuhr_nafl": 0,
            "asr_fardh": False, "asr_sunnah": 0, "asr_nafl": 0,
            "maghrib_fardh": False, "maghrib_sunnah": 0, "maghrib_nafl": 0,
            "isha_fardh": False, "isha_sunnah": 0, "isha_nafl": 0,
        })
        response = client.post("/logs/", json={
            "date": "2026-02-19",
            "fajr_fardh": True, "fajr_sunnah": 2, "fajr_nafl": 0,
            "dhuhr_fardh": True, "dhuhr_sunnah": 0, "dhuhr_nafl": 0,
            "asr_fardh": False, "asr_sunnah": 0, "asr_nafl": 0,
            "maghrib_fardh": False, "maghrib_sunnah": 0, "maghrib_nafl": 0,
            "isha_fardh": False, "isha_sunnah": 0, "isha_nafl": 0,
        })
        assert response.status_code == 201
        assert response.json()["fajr_fardh"] is True

    def test_range_query(self, client):
        self._login(client)
        for day in ["2026-02-18", "2026-02-19"]:
            client.post("/logs/", json={
                "date": day,
                "fajr_fardh": True, "fajr_sunnah": 0, "fajr_nafl": 0,
                "dhuhr_fardh": True, "dhuhr_sunnah": 0, "dhuhr_nafl": 0,
                "asr_fardh": True, "asr_sunnah": 0, "asr_nafl": 0,
                "maghrib_fardh": True, "maghrib_sunnah": 0, "maghrib_nafl": 0,
                "isha_fardh": True, "isha_sunnah": 0, "isha_nafl": 0,
            })
        response = client.get("/logs/range/?start=2026-02-18&end=2026-02-19")
        assert response.status_code == 200
        assert len(response.json()) == 2


class TestPerformanceEndpoints:
    def _login_and_log(self, client):
        client.post("/auth/google-login", json={"id_token": "mock"})
        client.post("/logs/", json={
            "date": "2026-02-19",
            "fajr_fardh": True, "fajr_sunnah": 2, "fajr_nafl": 0,
            "dhuhr_fardh": True, "dhuhr_sunnah": 6, "dhuhr_nafl": 0,
            "asr_fardh": True, "asr_sunnah": 0, "asr_nafl": 0,
            "maghrib_fardh": True, "maghrib_sunnah": 2, "maghrib_nafl": 0,
            "isha_fardh": True, "isha_sunnah": 4, "isha_nafl": 0,
        })

    def test_performance(self, client):
        self._login_and_log(client)
        response = client.get("/performance/?start=2026-02-19&end=2026-02-19")
        assert response.status_code == 200
        data = response.json()
        assert data["average_score"] == 100.0
        assert data["total_fardh_completed"] == 5

    def test_performance_empty_range(self, client):
        client.post("/auth/google-login", json={"id_token": "mock"})
        response = client.get("/performance/?start=2026-01-01&end=2026-01-31")
        assert response.status_code == 200
        assert response.json()["average_score"] == 0.0
