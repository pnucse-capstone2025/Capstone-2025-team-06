import numpy as np, pandas as pd, shap

def top_shap_for_row(pipeline, cols, row_df, topk=6):
    try:
        expl = shap.Explainer(pipeline.predict_proba)
        sv = expl(row_df).values[0]
        shap_map = {cols[i]: float(sv[i]) for i in range(len(cols))}
        return dict(sorted(shap_map.items(), key=lambda kv: abs(kv[1]), reverse=True)[:topk])
    except Exception:
        # light fallback
        return {}
