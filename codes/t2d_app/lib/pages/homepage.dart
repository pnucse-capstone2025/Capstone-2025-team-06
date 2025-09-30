import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final _t2dKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _scienceKey = GlobalKey();

  Future<void> _to(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.black.withOpacity(0.9),
            title: const Text('T2D Digital Twin'),
            actions: [
              TextButton(onPressed: () => _to(_t2dKey), child: const Text('T2D')),
              TextButton(onPressed: () => _to(_aboutKey), child: const Text('About')),
              TextButton(onPressed: () => _to(_scienceKey), child: const Text('Science')),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Login'),
                ),
              ),
            ],
          ),

          // Hero
          SliverToBoxAdapter(
            child: Container(
              height: 520,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: Colors.black,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'A personal Digital Twin for Type 2 Diabetes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      // short tagline you asked for
                      'A research prototype that analyzes labs, images, and surveys to preview diabetes risks '
                      'and complications — then explains the “why” in human terms.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurface.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _to(_t2dKey),
                      child: const Text('Learn more ↓'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Section 1 — T2D
          _section(
            key: _t2dKey,
            title: 'Understanding Type 2 Diabetes',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _P(
                  'Type 2 Diabetes (T2D) is a chronic metabolic disease where the body does not respond '
                  'properly to insulin or cannot make enough of it. Glucose builds up in the blood and can '
                  'damage vessels and organs over time.',
                ),
                _P(
                  'More than 537 million adults live with diabetes globally, and most have T2D. Lifestyle '
                  'factors like excess weight, diet, and inactivity interact with genetics to raise risk.',
                ),
                _P(
                  'Unmanaged T2D can lead to cardiovascular disease, kidney failure, diabetic retinopathy, '
                  'and diabetic foot ulcers. Many people are undiagnosed until complications appear.',
                ),
                _P(
                  'Early detection, continuous monitoring, and timely medical care are essential. Prevention '
                  'relies on lifestyle changes and regular screening guided by clinicians.',
                ),
              ],
            ),
          ),

          // Section 2 — About project (science-y + disclaimer)
          _section(
            key: _aboutKey,
            title: 'About the Project',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _P(
                  'This Digital Twin aggregates multimodal evidence about T2D: retinal images, foot images, '
                  'electronic health records, and population surveys. Models classify complications, estimate risk, '
                  'and surface drivers (e.g., glucose, HbA1c, BMI, lipids).',
                ),
                const _P(
                  'The goal is to help people preview risks, understand patterns, and engage with educational content '
                  'tailored to their inputs. Insights are presented alongside transparent visuals such as confusion '
                  'matrices, ROC/PR curves, and feature importance.',
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Disclaimer: This is a student research prototype. It does not provide medical advice and is not a '
                    'substitute for professional diagnosis or treatment. If you have concerns about your health, '
                    'please consult a qualified clinician.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Section 3 — Science & datasets (cards with images)
          _section(
            key: _scienceKey,
            title: 'Science & Datasets',
            child: Column(
              children: [
                _datasetCard(
                  title: 'DFU — Diabetic Foot Ulcers (image classification)',
                  description:
                      'Classifies foot images as healthy skin, ulcer, or wound. Ulcer detection supports early care '
                      'to reduce infection and amputation risk. Our test confusion matrix shows very low misclassification.',
                  assetPaths: const [
                    // pick 2–3 best (see “Which images to pick” below) and put them under assets/dfu/
                    'assets/dfu/confusion.png',
                    'assets/dfu/grid.png',
                  ],
                ),
                const SizedBox(height: 16),
                _datasetCard(
                  title: 'DR — Diabetic Retinopathy (fundus grading)',
                  description:
                      'Grades retinal fundus photos from No DR to Proliferative DR. Strong precision/recall across stages; '
                      'helps flag patients needing ophthalmology follow-up.',
                  assetPaths: const [
                    'assets/dr/confusion.png',
                    'assets/dr/samples.png',
                  ],
                ),
                const SizedBox(height: 16),
                _datasetCard(
                  title: 'MIMIC-IV — Clinical Records (risk modeling)',
                  description:
                      'Predicts T2D risk from EHR features (e.g., HbA1c, glucose, lipids, LOS). Models like RF/KNN show strong '
                      'discrimination (see ROC/PR). Demonstrates early warning from structured hospital data.',
                  assetPaths: const [
                    'assets/mimic/roc.png',
                    'assets/mimic/admissions.png',
                  ],
                ),
                const SizedBox(height: 16),
                _datasetCard(
                  title: 'NHANES — Population Survey & Biomarkers',
                  description:
                      'Combines survey, anthropometrics, and labs to model population-level T2D risk. Feature importance highlights '
                      'glucose and BMI; correlation heatmap reveals metabolic relationships.',
                  assetPaths: const [
                    'assets/nhanes/corr.png',
                    'assets/nhanes/feature_importance.png',
                  ],
                ),
              ],
            ),
          ),

          // Footer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '© ${DateTime.now().year} T2D Digital Twin — Graduation Project',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _section({
    Key? key,
    required String title,
    required Widget child,
  }) {
    return SliverToBoxAdapter(
      key: key,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// simple paragraph styled for dark mode
class _P extends StatelessWidget {
  final String text;
  const _P(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.86),
            height: 1.35,
          ),
        ),
      );
}

/// dataset card with a responsive image row
class _datasetCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> assetPaths;
  const _datasetCard({
    required this.title,
    required this.description,
    required this.assetPaths,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0x101FFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x22FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(description,
              style: TextStyle(color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: assetPaths
                .map((p) => _imageBox(p, width: 290, height: 180))
                .toList(),
          ),
        ]),
      ),
    );
  }

  Widget _imageBox(String assetPath, {double width = 280, double height = 160}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        // don’t crash if the asset isn’t added yet:
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: const Color(0x22FFFFFF),
          alignment: Alignment.center,
          child: const Text('Add:\nassets/…', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
