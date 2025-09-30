import requests

payload = {
    "model_id": "mimic_t2d",
    "context": {"user_id": "demo", "patient_id": "P001"},
    "features": {
        "hba1c_first": 6.4,
        "glucose_first": 125,
        "chol_total_first": 190,
        "chol_hdl_first": 50,
        "chol_ldl_first": 120,
        "triglycerides_first": 160,
    },
}

resp = requests.post("http://127.0.0.1:8000/predict/tabular", json=payload)
print("Status:", resp.status_code)
print("Response:", resp.json())
