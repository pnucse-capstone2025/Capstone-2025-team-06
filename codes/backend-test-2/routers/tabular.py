import time, io, base64
import numpy as np, pandas as pd
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.deps import get_db
from app.config import settings
from app.registry import REGISTRY
from app.schemas.tabular import TabularPredict, TabularPredictOut
from app.db.models import PredictionLog, SimulationLog
from app.utils.shap_utils import top_shap_for_row

router = APIRouter(prefix="/predict")

THR = {"low": settings.thresh_low, "high": settings.thresh_high}

def align_row(d, cols):
    df = pd.DataFrame([d])
    for c in cols:
        if c not in df.columns: df[c] = np.nan
    return df[cols]

@router.post("/tabular", response_model=TabularPredictOut)
def predict_tabular(req: TabularPredict, db: Session = Depends(get_db)):
    if req.model_id not in REGISTRY or REGISTRY[req.model_id]["type"]!="tabular":
        raise HTTPException(400, "unknown tabular model_id")
    bundle = REGISTRY[req.model_id]
    pipe, cols = bundle["model"], bundle["cols"]

    row = align_row(req.features, cols)
    proba = float(pipe.predict_proba(row)[0,1])
    cat = "low" if proba<THR["low"] else ("mild" if proba<THR["high"] else "high")
    shap_top = top_shap_for_row(pipe, cols, row, topk=6)

    log = PredictionLog(
        user_id=getattr(req.context, "user_id", None) if req.context else None,
        patient_id=getattr(req.context, "patient_id", None) if req.context else None,
        model_id=req.model_id, inputs=req.features,
        outputs={"probability": proba, "category": cat, "shap_top": shap_top},
        created_at=int(time.time())
    )
    db.add(log); db.commit()
    return {"probability": proba, "category": cat, "shap_top": shap_top, "thresholds": THR}
