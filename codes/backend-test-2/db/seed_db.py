# app/db/seed_db.py
from app.db.base import SessionLocal
from app.db.models import User

def main():
    db = SessionLocal()
    try:
        if not db.query(User).filter(User.id=="demo").first():
            db.add(User(id="demo", email="demo@example.com", role="patient"))
            db.commit()
            print("Seeded user: demo")
        else:
            print("User 'demo' already exists")
    finally:
        db.close()

if __name__ == "__main__":
    main()
