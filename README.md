# Salah Tracker

Track daily prayers, visualize consistency, and measure performance.

## Project Structure

- `backend/`: FastAPI application with SQLite database.
- `frontend/`: Flutter web application.
- `flutter_sdk/`: Embedded Flutter SDK used by this project.

## Prerequisites

- **Python**: 3.10 or higher.
- **Node.js**: (Optional, if using any JS tools).
- **Flutter**: Install Flutter by following the [official installation guide](https://docs.flutter.dev/get-started/install).

### Standard Flutter Installation (Recommended)

To install Flutter on your system:

1. **Download the Flutter SDK** for your OS from the [official website](https://docs.flutter.dev/get-started/install).
2. **Extract the tool** and add the `flutter/bin` directory to your system `PATH`.
3. **Run `flutter doctor`** to verify the installation and install any missing dependencies.

*Note: This project also includes an embedded Flutter SDK in `flutter_sdk/` for convenience in restricted environments.*

---

## Backend Setup

1. **Navigate to the backend directory**:
   ```bash
   cd backend
   ```

2. **Create and activate a virtual environment**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure Environment Variables**:
   Copy `.env.example` to `.env` and adjust as needed:
   ```bash
   cp .env.example .env
   ```

5. **Run the Backend**:
   ```bash
   uvicorn main:app --reload
   ```
   The API will be available at [http://localhost:8000](http://localhost:8000) and documentation at [http://localhost:8000/docs](http://localhost:8000/docs).

---

## Frontend Setup

The project uses a local Flutter SDK located in the root directory. Use the absolute path if it is not in your system `PATH`.

1. **Navigate to the frontend directory**:
   ```bash
   cd frontend
   ```

2. **Install Flutter dependencies**:
   ```bash
   ../flutter_sdk/bin/flutter pub get
   ```

3. **Run the Application (Web)**:
   ```bash
   ../flutter_sdk/bin/flutter run -d chrome
   ```

---

## Troubleshooting

- **Flutter Command Not Found**: If you get a "command not found" error, ensure you are using the path to the embedded SDK: `../flutter_sdk/bin/flutter`.
- **Backend Connection**: Ensure the backend is running at `http://localhost:8000` before starting the frontend to ensure data syncing works correctly.
