# app/routers/image.py
import io, base64, time
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.orm import Session
import torchvision.transforms as T
from PIL import Image
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import torch.nn.functional as F
import torch

from app.registry import REGISTRY
from app.config import settings
from app.deps import get_db
from app.db.models import PredictionLog
from app.schemas.image import ImagePredictOut
from app.utils.gradcam import explain_image

router = APIRouter(prefix="/predict", tags=["image"])

def preprocess_img(file: UploadFile, size=224):
    img = Image.open(io.BytesIO(file.file.read())).convert("RGB")
    tfm = T.Compose([
        T.Resize((size, size)),
        T.ToTensor(),
        T.Normalize([0.485,0.456,0.406],[0.229,0.224,0.225])
    ])
    return img, tfm(img).unsqueeze(0)

@router.post("/image")
async def predict_image(model_id: str, file: UploadFile = File(...), db: Session = Depends(get_db)):
    if model_id not in REGISTRY or REGISTRY[model_id]["type"] != "image":
        raise HTTPException(400, "unknown image model_id")
    bundle = REGISTRY[model_id]
    model, device, labels = bundle["model"], bundle["device"], bundle.get("labels")

    raw_img, tensor = preprocess_img(file)

    # Forward once to get probability vector & top class
    with torch.no_grad():
        out = model(tensor.to(device))
    if out.ndim == 2 and out.shape[1] >= 2:
        probs = F.softmax(out, dim=1)[0].detach().cpu().numpy()  # (C,)
    else:
        p1 = float(torch.sigmoid(out)[0].item())
        probs = np.array([1.0 - p1, p1])

    top_idx = int(np.argmax(probs))
    top_prob = float(probs[top_idx])
    class_name = labels[top_idx] if labels and top_idx < len(labels) else str(top_idx)

    # Explain for top class (Grad-CAM or saliency fallback)
    try:
        prob_scalar, heat, _ = explain_image(model, tensor, device=device, class_idx=top_idx)
    except Exception:
        raise HTTPException(status_code=500, detail="Grad-CAM failed")

    # Overlay heatmap
    fig, ax = plt.subplots(1, 1, figsize=(3, 3))
    ax.imshow(raw_img)
    ax.imshow(heat, cmap="jet", alpha=0.35)
    ax.axis("off")
    buf = io.BytesIO(); fig.savefig(buf, format="png", bbox_inches="tight"); plt.close(fig)
    b64 = base64.b64encode(buf.getvalue()).decode("utf-8")

    # Build per-class probs dict for the UI
    if labels and len(labels) == len(probs):
        probs_dict = {labels[i]: float(probs[i]) for i in range(len(labels))}
    else:
        probs_dict = {str(i): float(probs[i]) for i in range(len(probs))}

    # Log
    db.add(PredictionLog(
        user_id=None, patient_id=None, model_id=model_id,
        inputs={"filename": file.filename},
        outputs={"top_class": class_name, "top_prob": top_prob, "probs": probs_dict},
        created_at=int(time.time())
    ))
    db.commit()

    return {
        "top_class": class_name,
        "top_prob": top_prob,
        "probs": probs_dict,
        "explanation_b64": f"data:image/png;base64,{b64}"
    }
