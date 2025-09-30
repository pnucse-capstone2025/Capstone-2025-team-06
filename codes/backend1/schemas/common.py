from pydantic import BaseModel
from typing import Optional, Dict, Any

class UserContext(BaseModel):
    user_id: Optional[str] = None
    patient_id: Optional[str] = None

class ChartSeries(BaseModel):
    labels: list
    datasets: list
