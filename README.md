# A Multimodal Digital Twin for Type 2 Diabetes Patients

> Team **SheCodes** · Advisor: **Prof. Song Giltae** · Pusan National University  
> **Disclaimer:** This project provides educational information and is **not a medical diagnosis tool**.

---

### 1. 프로젝트 배경

#### 1.1. 국내외 시장 현황 및 문제점
Type 2 Diabetes (T2D) is a global health crisis affecting **~589M adults in 2024**, projected to reach **853M by 2050**.  
- Existing predictive models are mostly **unimodal** (lab only, survey only).  
- Early complications such as **Diabetic Retinopathy (DR)** and **Diabetic Foot Ulcers (DFU)** are often detected too late → blindness, amputations.  
- Lack of **explainability** and **personalized lifestyle guidance** limits usability.   

#### 1.2. 필요성과 기대효과
Our project introduces a **multimodal digital twin system** that:  
- Integrates **tabular risk prediction (NHANES, MIMIC-IV)** with **imaging models (DR, DFU)**.  
- Adds a **Gemini-powered coaching layer** for lifestyle planning, education packs, and weekly reports.  
- Expected outcomes:  
  - Earlier complication detection.  
  - More accurate multimodal prediction (AUC ≈ 0.88 vs. unimodal ≈ 0.81 in report).  
  - User-friendly explanations via Grad-CAM.  
  - Long-term patient engagement through coaching.  

---

### 2. 개발 목표

#### 2.1. 목표 및 세부 내용
- **Flutter Web App** (dark theme) with Supabase authentication.  
- **4 prediction models**:  
  1. **NHANES survey model** (Random Forest)  
  2. **MIMIC-IV lab model** (Logistic Regression)  
  3. **DFU classifier** (EfficientNet-B3)  
  4. **DR classifier** (EfficientNet-B3)  
- **Gemini coaching layer** to generate meal plans, activity tips, education packs, lifestyle suggestions, and weekly summaries.  
- **Supabase storage** for all user inputs/outputs.  

#### 2.2. 기존 서비스 대비 차별성
- Multimodal: combines tabular + imaging models.
- Generative AI coaching: Gemini layer, not just risk scores.  
- Academic openness: transparent methods, no black box.  

#### 2.3. 사회적 가치 도입 계획
- Preventive healthcare.  
- Accessible patient education.  
- Sustainability through open academic research.  

---

### 3. 시스템 설계

#### 3.1. 시스템 구성도
![(System Architecture)](system_architecture.jpg)  

#### 3.2. 사용 기술
- **Frontend**: Flutter Web (Dart), Supabase Auth  
- **Backend**: FastAPI, PostgreSQL (Supabase), Torch/TorchVision, scikit-learn  
- **Models**: RF, Logistic Regression, EfficientNet-B3   
- **AI Coaching**: Gemini API → structured JSON rendered in Flutter  

---

### 4. 개발 결과

0) Homepage opens automatically and provides information about the diabetes and the project the the User.
1) User signs up / logs in via Supabase.
2) User chooses an option:
   - Enter survey/lab values (NHANES / MIMIC-IV forms)
   - Upload medical images (DFU / DR)
3) Frontend (Flutter) sends the request to FastAPI backend.
4) Backend routes to the appropriate model:
   - Tabular models → NHANES RF / MIMIC-IV LogReg
   - Imaging models → EfficientNet-B3 (DFU / DR)
5) Backend generates explanations:
   - Imaging → Grad-CAM heatmaps
6) Backend aggregates results and returns JSON to the frontend.
7) Frontend renders:
   - Risk/Severity scores, explanations, and historical view
8) Gemini coaching API is called with the results to generate:
   - Weekly report, meal/activity plans, education tips
9) All inputs/outputs are stored in Supabase (for longitudinal review).
10) User views results on dashboard and can revisit past sessions.


#### 4.2. 기능 설명 및 주요 기능 명세서
- **Authentication**: Supabase login/signup.  
- **NHANES Model**:  
  - AUROC ≈ 0.99 (train/test split in report).  
  - Feature importance shows **HbA1c, glucose, BMI, SBP** as key drivers.  
  - ![Top Features – Random Forest (NHANES)](Unknown-19.png)
  - ![](nhanes_screen.jpeg)
- **MIMIC-IV Model**:  
  - Logistic Regression achieved **AUROC ≈ 0.77, AP ≈ 0.44** (report).  
  - Key predictors: **HbA1c, glucose, triglycerides, LDL**.  
  - Provides coefficients.  
  - ![ROC Curve – MIMIC-IV](roc_mimic.png)  
  - ![Precision–Recall Curve – MIMIC-IV](pr_mimic.png)  
  - ![Predicted Probability Distribution – MIMIC-IV](prob_dist_mimic.png) 
  - ![](mimic_screen.jpeg)   
- **DFU Model**:  
  - EfficientNet-B3 classifier trained on diabetic foot ulcer dataset.  
  - Confusion mostly occurs between **Wound vs Ulcer** categories.  
  - Grad-CAM highlights wound regions for interpretability.  
  - ![Confusion Matrix – DFU](confusion.png)  
  - ![Sample Predictions – DFU](Unknown-15.png) 
  - ![](dfu_screen.jpeg)  
- **DR Model**:  
  - EfficientNet-B3 classifier trained on the **APTOS 2019 dataset**.  
  - Performs **5-class severity grading** (No_DR, Mild, Moderate, Severe, Proliferative_DR).  
  - Main confusion occurs between **Moderate vs Severe** classes.  
  - Grad-CAM highlights lesion regions on retina images for interpretability.  
  - ![Confusion Matrix – DR](confusion_dr.png)  
  - ![Grad-CAM Example – DR](Unknown-13_dr.png)  
  - ![Classification Report – DR](TEST_DR.png)  
  - ![](dr_screen.jpeg)
- **Gemini Coaching**:  
  - Structured outputs: weekly reports, meal/activity plans, education packs, lifestyle tips.  
  - Rendered as **cards in Flutter**.  
  - ![Gemini page in UI](gemini_screen1.jpeg)  
  - ![Gemini page in UI](gemini_screen2.jpeg) 
- **Supabase Storage**: securely logs all inputs & predictions for longitudinal review.  

#### 4.3. 디렉토리 구조
![](repo_tree.png) 

```
.
├── Datasets
│   ├── DFU 2
│   │   └── Patches
│   ├── DFU.zip
│   ├── DFU_org
│   │   ├── test
│   │   ├── train
│   │   └── valid
│   ├── DIABETIC_RETINA
│   │   ├── colored_images
│   │   └── train.csv
│   ├── DIABETIC_RETINA.zip
│   ├── MIMIC-2.2
│   │   ├── admissions.csv
│   │   ├── diagnosis.csv
│   │   ├── edstays.csv
│   │   ├── medrecon.csv
│   │   ├── pyxis.csv
│   │   ├── triage.csv
│   │   └── vitalsign.csv
│   ├── MIMIC-2.2.zip
│   ├── NHANES-2
│   │   ├── demographic.csv
│   │   ├── diet.csv
│   │   ├── examination.csv
│   │   ├── labs.csv
│   │   ├── medications.csv
│   │   ├── merged.csv
│   │   └── questionnaire.csv
│   └── NHANES-2.zip
├── T2D_models
│   ├── best_efficientnet_dfu_checkpoint.pth
│   ├── dfu-2.pt
│   ├── dfu.pt
│   ├── dr.pt
│   ├── nhanes-final.joblib
│   ├── nhanes.joblib
│   ├── t2d_lab_model.joblib
│   ├── visualizations
│   │   ├── dfu_pics
│   │   ├── dr_pics
│   │   ├── mimic-pics
│   │   └── nhanes_pics
│   └── visualizations.zip
├── codes
│   ├── app.txt
│   ├── gemini_t2d_test
│   │   ├── flutter_application_1
│   │   └── health-ai-app
│   ├── gemini_t2d_test.zip
│   ├── health-ai-backend_test 2.zip
│   ├── model training (Colab)
│   │   ├── DFU_EffNet_22-2.ipynb
│   │   ├── DR_EfNet-2.ipynb
│   │   ├── MIMIC_IV.ipynb
│   │   └── NHANES_FINAL_2.ipynb
│   ├── t2d_app
│   │   ├── README.md
│   │   ├── analysis_options.yaml
│   │   ├── android
│   │   ├── assets
│   │   ├── build
│   │   ├── devtools_options.yaml
│   │   ├── ios
│   │   ├── lib
│   │   ├── linux
│   │   ├── macos
│   │   ├── pubspec.lock
│   │   ├── pubspec.yaml
│   │   ├── t2d_app.iml
│   │   ├── test
│   │   ├── web
│   │   └── windows
│   ├── t2d_app 2.zip
│   └── t2d_backend
│       ├── 0a3202889f4d.png
│       ├── 520.jpg
│       ├── 74.jpg
│       ├── 9.jpg
│       ├── app
│       ├── app.env
│       ├── healthai.db
│       ├── requirements.txt
│       ├── run.sh
│       └── test_request.py
├── docs
│   ├── 02.포스터
│   │   └── 2025포스터_졸업과06_SheCodes_A_Multimodal_Digital_Twin_for_T2D_Patients_송길태.pdf
│   ├── 03.발표자료
│   │   └── Team SheCodes_ Multimodal Digital Twin for Type 2 Diabetes.pdf
│   ├── 1.보고서
│   │   └── 2025전기_최종보고서_06_SheCodes.pdf
│   ├── 4.동영상
│   │   ├── 2025전기졸업과제동영상_06_A_SheCodes.MOV
│   │   └── 2025전기졸업과제동영상_06_A_SheCodes.mp4
│   └── brochure
│       ├── 1.png
│       └── 2.png
└── readme
    ├── README.md
    ├── TEST_DR.png
    ├── Unknown-13_dr.png
    ├── Unknown-15.png
    ├── Unknown-19.png
    ├── confusion.png
    ├── confusion_dr.png
    ├── dfu_screen.jpeg
    ├── dr_screen.jpeg
    ├── gemini_screen1.jpeg
    ├── gemini_screen2.jpeg
    ├── mimic_screen.jpeg
    ├── nhanes_screen.jpeg
    ├── poster.jpg
    ├── pr_mimic.png
    ├── prob_dist_mimic.png
    ├── roc_mimic.png
    └── system_architecture.jpg

43 directories, 75 files
```

#### 4.4. 산업체 멘토링 의견 및 반영 사항
- Must include **medical disclaimer** → implemented.  
- Gemini output should be **structured** → implemented.  
- Track **model versions** & logs → planned for future.  

---

### 5. 설치 및 실행 방법

#### 5.1. 설치절차 및 실행 방법

**Backend**
```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Frontend**
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

#### 5.2. 오류 발생 시 해결 방법
- **Supabase email verification**: disable or confirm manually in Supabase console.  
- **CORS issues**: add `http://localhost:xxxx` to FastAPI CORS.  
- **Missing model weights**: place `nhanes.joblib`, `t2d_lab_model.joblib`, `dfu-2.pt`, `dr.pt` in correct `backend/models/weights/` folder (update `config.py` if needed).  
- **CPU inference**: Grad-CAM slower, but works.  

---

### 6. 소개 자료 및 시연 영상

#### 6.1. 프로젝트 소개 자료
![Poster](poster.jpg) 

#### 6.2. 시연 영상
[YouTube demo video](https://youtu.be/fQ592dZjNhk?si=m6krqeyzf57KnAAu) 

---

### 7. 팀 구성

#### 7.1. 팀원별 소개 및 역할 분담
- **Pak Elina (202255631)** — Model development, benchmarking, multimodal pipeline integration, and Documentation.  
- **Qonysbekova Yenglik (202255637)** — Data preprocessing, Application UI prototyping, Flutter development, and Documentation.  
- **Bakhieva Aysuliu (202255545)** — Data collection, preprocessing, and documentation sup- port.  

#### 7.2. 팀원 별 참여 후기
 
Pak Elina: Working together on this project taught me a lot about teamwork and supporting each other.
Even though we faced some challenges, like technical issues (Gemini models issues and models predictions issues), tons is paper work and deadlines, we managed to push through.
I learned how important communication and patience are, and I feel I grew both personally and academically from this experience.

Qonysbekova Yenglik: This was my first time working with Flutter, and learning a new framework on the go was definitely the biggest challenge for me. Also, coordinating work among three people wasn’t easy in the beginning, and we often struggled to keep track of who had written which parts of the code, what tasks were already completed, and what changes were made. We learned each other’s strengths and adjusted our task division, which made collaboration smoother. Through this process, I not only picked up new technical skills but also gained experience in team communication, coordination, and problem-solving, which I believe will be valuable in future projects.

Bakhieva Aysuliu: Working on this project taught me about teamwork and mutual support. We faced challenges like data pipeline errors, heavy paperwork, and tight deadlines, but pushed through together. Data collection was particularly difficult since medical datasets require special permissions and policies, taking considerable time to access. Despite the overwhelming workload, I learned how important communication and patience are. I grew both personally and academically, developing stronger organizational skills and deeper appreciation for collaboration.

---

### 8. 참고 문헌 및 출처

- Jiang, Y. et al. *Digital twins for type 2 diabetes: from modeling to application.* npj Digital Medicine (2023).  
- Ma, Y., et al. (2024). *Multimodal data fusion for disease prediction.* Scientific Reports.  
- APTOS. (2019). *APTOS 2019 Blindness Detection Dataset.* Kaggle.  
- Sovit Rath. (2019). *Diabetic Retinopathy 224x224 2019 Data* [Dataset]. Kaggle.  
- pkdarabi. (2021). *Diagnosis of Diabetic Retinopathy by CNN (PyTorch)* [Notebook]. Kaggle.  
- Costa, P., Galdran, A., Meyer, M. I., Niemeijer, M., Abràmoff, M., Mendonça, A. M., & Campilho, A. (2020). *End-to-end adversarial retinal image synthesis.* SoftwareX, 11, 100372.  
- Nature Scientific Reports. (2025). *Deep learning-based diabetic retinopathy detection: recent advances and challenges.* Scientific Reports.  
- Alzubaidi, L., Zhang, J., & Santamaría, J. (2022). *Diabetic foot ulcer detection using deep learning approaches.* Discover Artificial Intelligence, 2, 15.  
- Pratomo, Y. (2023). *Wound Dataset* [Dataset]. Kaggle.  
- Liu, C., et al. (2024). *Identifying top ten predictors of type 2 diabetes through machine learning analysis of UK Biobank data.* Scientific Reports.  
- Jung, J., et al. (2025). *Prediction model for type 2 diabetes mellitus and its association with mortality using machine learning in three independent cohorts from South Korea, Japan, and the UK: a model development and validation study.* eClinicalMedicine, 75, 102400.  
- Li, W., et al. (2024). *Type 2 diabetes prediction method based on dual-teacher knowledge distillation and feature enhancement.* Scientific Reports.  
- IEEE DataPort. (2024). *Type 2 Diabetes Dataset.*  
- Khera, A. V., et al. (2025). *Machine learning-based reproducible prediction of type 2 diabetes subtypes.* Nature Medicine.  
- Hassan, M., et al. (2025). *Prediction of Type 2 Diabetes using Machine Learning Classification Methods.* Artificial Intelligence in Medicine.  
- Yu, W., et al. (2017). *Type 2 diabetes mellitus prediction model based on data mining.* Informatics in Medicine Unlocked, 9, 100–107.  
- Tiwari, P., & Kumar, R. (2018). *Diabetes detection using deep learning algorithms.* ICT Express, 4(4), 243–246.  
- Zhou, H., et al. (2025). *Association between triglyceride-glucose-body mass index and adverse prognosis in elderly patients with severe heart failure and type 2 diabetes: a retrospective study based on the MIMIC-IV database.* Cardiovascular Diabetology, 24, 18.  
- **TwinHealth official website**: [https://usa.twinhealth.com/](https://usa.twinhealth.com/)  
- Banga et al. (2024). *Personalized digital twins for chronic metabolic disease management.* npj Digital Medicine, 7(2): Article 54. [Link](https://pmc.ncbi.nlm.nih.gov/articles/PMC10853398/)  


---
