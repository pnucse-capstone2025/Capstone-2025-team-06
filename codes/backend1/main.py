# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.db.init_db import init as init_db
from app.registry import load_all, REGISTRY
from app.routers import tabular, image

def create_app():
    app = FastAPI(title="Health AI Hub", version="1.0")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[settings.cors_origins],
        allow_methods=["*"], allow_headers=["*"]
    )
    init_db()
    load_all()
    app.include_router(tabular.router)
    app.include_router(image.router)

    @app.get("/")
    def root():
        return {"ok": True, "message": "Health AI backend", "docs": "/docs"}

    @app.get("/health")
    def health():
        return {
            "ok": True,
            "models_loaded": list(REGISTRY.keys()),
            "thresholds": {"low": settings.thresh_low, "high": settings.thresh_high},
        }

    return app

app = create_app()
