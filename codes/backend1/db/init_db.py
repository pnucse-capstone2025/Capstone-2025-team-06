# app/db/init_db.py
from app.db.base import Base, engine
import app.db.models  # ensure models are imported

def init():
    Base.metadata.create_all(bind=engine)

if __name__ == "__main__":
    init()