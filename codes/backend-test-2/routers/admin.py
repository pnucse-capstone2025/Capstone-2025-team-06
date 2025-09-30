# app/routers/admin.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.deps import get_db
from app.db.models import PredictionLog, SimulationLog

router = APIRouter(prefix="/admin", tags=["admin"])

@router.get("/predictions")
def list_predictions(limit: int = 20, db: Session = Depends(get_db)):
    rows = db.query(PredictionLog).order_by(PredictionLog.id.desc()).limit(limit).all()
    return [
        {
            "id": r.id,
            "user_id": r.user_id,
            "patient_id": r.patient_id,
            "model_id": r.model_id,
            "inputs": r.inputs,
            "outputs": r.outputs,
            "created_at": r.created_at,
        }
        for r in rows
    ]

@router.get("/simulations")
def list_simulations(limit: int = 20, db: Session = Depends(get_db)):
    rows = db.query(SimulationLog).order_by(SimulationLog.id.desc()).limit(limit).all()
    return [
        {
            "id": r.id,
            "user_id": r.user_id,
            "patient_id": r.patient_id,
            "model_id": r.model_id,
            "sim_type": r.sim_type,
            "inputs": r.inputs,
            "outputs": r.outputs,
            "created_at": r.created_at,
        }
        for r in rows
    ]
