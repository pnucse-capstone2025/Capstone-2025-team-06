from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from app.schemas.common import UserContext

class TabularPredict(BaseModel):
    context: Optional[UserContext] = None
    model_id: str = Field(..., alias="model_id")  # keep external name the same
    features: Dict[str, Any]

    # turn off protected namespaces to silence warning
    model_config = {
        "populate_by_name": True,
        "protected_namespaces": ()  # <— this line removes the warning
    }

class TabularPredictOut(BaseModel):
    probability: float
    category: str
    shap_top: Dict[str, float]
    thresholds: Dict[str, float]
