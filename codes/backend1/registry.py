# app/registry.py
import os, json, warnings
import joblib, torch
from torch.serialization import SourceChangeWarning
from app.config import settings

REGISTRY = {}

# ---- Add this: per-model class label lists (index order must match your model outputs) ----
IMAGE_LABELS = {
    "dfu": ["Healthy skin", "Ulcer", "Wounds"],  # 3 classes
    "dr":  ['Mild', 'Moderate', 'No_DR', 'Proliferate_DR', 'Severe'],  # 5 classes
}

def load_all():
    base = settings.models_dir

    # Tabular models...
    for mid, fname in [("mimic_t2d", "t2d_lab_model.joblib"),
                       ("nhanes", "nhanes.joblib")]:
        path = os.path.join(base, fname)
        if not os.path.exists(path): continue
        pipe = joblib.load(path)
        if hasattr(pipe, "feature_names_in_"):
            feature_names = list(pipe.feature_names_in_)
        else:
            cols_path = path.replace(".joblib", ".cols.json")
            feature_names = json.load(open(cols_path)) if os.path.exists(cols_path) else []
        REGISTRY[mid] = {"type": "tabular", "model": pipe, "cols": feature_names}

    # Image models (TorchScript or eager) + attach labels
    device = "cuda" if torch.cuda.is_available() else "cpu"
    for mid, fname in [("dfu", "dfu-2.pt"), ("dr", "dr.pt")]:
        p = os.path.join(base, fname)
        if not os.path.exists(p): continue
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", SourceChangeWarning)
            try:
                model = torch.jit.load(p, map_location=device)
            except Exception:
                model = torch.load(p, map_location=device)
        model.eval()
        REGISTRY[mid] = {
            "type": "image",
            "model": model.to(device),
            "device": device,
            "labels": IMAGE_LABELS.get(mid, None)  # <- attach labels (or None)
        }

    print("[registry] loaded:", {k: v["type"] for k, v in REGISTRY.items()})
    return REGISTRY
