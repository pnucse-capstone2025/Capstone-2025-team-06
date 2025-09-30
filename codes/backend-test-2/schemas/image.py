from pydantic import BaseModel
from typing import Dict

class ImagePredictOut(BaseModel):
    probability: float
    label: str
    explanation_b64: str
    thresholds: Dict[str,float]
