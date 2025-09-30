from dotenv import load_dotenv
import os
from pathlib import Path

ENV_PATH = Path(__file__).resolve().parents[1] / "app.env"
load_dotenv(dotenv_path=ENV_PATH)

class Settings:
    database_url = os.getenv("DATABASE_URL", "sqlite:///./healthai.db")
    cors_origins = os.getenv("CORS_ORIGINS", "*")
    models_dir = os.getenv("MODELS_DIR", "app/assets/models")
    thresh_low = float(os.getenv("THRESH_LOW", 0.40))
    thresh_high = float(os.getenv("THRESH_HIGH", 0.65))

settings = Settings()
