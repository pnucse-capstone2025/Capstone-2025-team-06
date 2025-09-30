# app/db/models.py
from sqlalchemy import Column, Integer, String, JSON
from app.db.base import Base

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True)
    email = Column(String, unique=True, index=True)
    role = Column(String)

class PredictionLog(Base):
    __tablename__ = "prediction_logs"
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, index=True, nullable=True)
    patient_id = Column(String, index=True, nullable=True)
    model_id = Column(String, index=True)
    inputs = Column(JSON)
    outputs = Column(JSON)
    created_at = Column(Integer, index=True)

class SimulationLog(Base):
    __tablename__ = "simulation_logs"
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, index=True, nullable=True)
    patient_id = Column(String, index=True, nullable=True)
    model_id = Column(String, index=True)
    sim_type = Column(String)  # e.g. "whatif" or "temporal"
    inputs = Column(JSON)
    outputs = Column(JSON)
    created_at = Column(Integer, index=True)
