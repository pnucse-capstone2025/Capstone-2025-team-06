// lib/pages/nhanes_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/model_service.dart' as api;
import '../ui/result_card.dart';

class NhpPage extends StatefulWidget {
  const NhpPage({super.key});
  @override
  State<NhpPage> createState() => _NhpPageState();
}

class _NhpPageState extends State<NhpPage> {
  final age = TextEditingController(text: "45");          // RIDAGEYR
  final sexIdx = ValueNotifier<int>(0);                   // 0=>Male(1), 1=>Female(2)
  final smoker = ValueNotifier<bool>(false);              // SMQ020: 1=Yes, 2=No
  final bmi = TextEditingController(text: "28.5");        // BMXBMI
  final waist = TextEditingController(text: "95");        // BMXWAIST (cm)
  final sbp = TextEditingController(text: "125");         // BPXSY1
  final dbp = TextEditingController(text: "82");          // BPXDI1
  final glu = TextEditingController(text: "115");         // LBXGLU (mg/dL)
  final a1c = TextEditingController(text: "6.0");         // LBXGH  (%)
  final tc  = TextEditingController(text: "195");         // LBXTC
  final hdl = TextEditingController(text: "50");          // LBDHDD
  final ldl = TextEditingController(text: "120");         // LBDLDL
  final tg  = TextEditingController(text: "160");         // LBXTR

  Map<String, dynamic>? res;
  String? err;

  Future<void> _predict() async {
    try {
      final features = {
        "RIDAGEYR": double.tryParse(age.text),
        "RIAGENDR": (sexIdx.value == 0 ? 1 : 2),   // 1=Male,2=Female
        "SMQ020": smoker.value ? 1 : 2,            // 1=Yes,2=No
        "BMXBMI": double.tryParse(bmi.text),
        "BMXWAIST": double.tryParse(waist.text),
        "BPXSY1": double.tryParse(sbp.text),
        "BPXDI1": double.tryParse(dbp.text),
        "LBXGLU": double.tryParse(glu.text),
        "LBXGH": double.tryParse(a1c.text),
        "LBXTC": double.tryParse(tc.text),
        "LBDHDD": double.tryParse(hdl.text),
        "LBDLDL": double.tryParse(ldl.text),
        "LBXTR": double.tryParse(tg.text),
      };

      final r = await api.predictTabular("nhanes", features);
      setState(() { res = r; err = null; });
    } catch (e) {
      setState(() { err = e.toString(); res = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = (res?["probability"] as num?)?.toDouble() ?? 0;
    final cat = (res?["category"] ?? "").toString();
    final shap = (res?["shap_top"] as Map?)?.cast<String, dynamic>();
    final level = parseRisk(cat, score: p);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Row 1: Age / Sex / Smoker
        Row(children: [
          Expanded(child: _num("Age (RIDAGEYR)", age)),
          const SizedBox(width: 12),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: sexIdx,
              builder: (_, v, __) => DropdownButtonFormField<int>(
                value: v,
                items: const [
                  DropdownMenuItem(value: 0, child: Text("Male (1)")),
                  DropdownMenuItem(value: 1, child: Text("Female (2)")),
                ],
                onChanged: (x) => sexIdx.value = x ?? 0,
                decoration: const InputDecoration(labelText: "Sex (RIAGENDR)"),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: smoker,
              builder: (_, v, __) => SwitchListTile(
                title: const Text("Current Smoker (SMQ020)"),
                value: v,
                onChanged: (x) => smoker.value = x,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),

        // Row 2: BMI / Waist
        Row(children: [
          Expanded(child: _num("BMI (BMXBMI)", bmi)),
          const SizedBox(width: 12),
          Expanded(child: _num("Waist (BMXWAIST, cm)", waist)),
        ]),
        const SizedBox(height: 8),

        // Row 3: SBP / DBP
        Row(children: [
          Expanded(child: _num("SBP (BPXSY1)", sbp)),
          const SizedBox(width: 12),
          Expanded(child: _num("DBP (BPXDI1)", dbp)),
        ]),
        const SizedBox(height: 8),

        // Row 4: Glucose / A1c
        Row(children: [
          Expanded(child: _num("Glucose (LBXGLU)", glu)),
          const SizedBox(width: 12),
          Expanded(child: _num("HbA1c (LBXGH)", a1c)),
        ]),
        const SizedBox(height: 8),

        // Row 5: Total Chol / HDL
        Row(children: [
          Expanded(child: _num("Total Chol (LBXTC)", tc)),
          const SizedBox(width: 12),
          Expanded(child: _num("HDL (LBDHDD)", hdl)),
        ]),
        const SizedBox(height: 8),

        // Row 6: LDL / TG
        Row(children: [
          Expanded(child: _num("LDL (LBDLDL)", ldl)),
          const SizedBox(width: 12),
          Expanded(child: _num("Triglycerides (LBXTR)", tg)),
        ]),
        const SizedBox(height: 12),

        FilledButton(onPressed: _predict, child: const Text("Predict")),
        const SizedBox(height: 12),

        if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),

        if (res != null) ...[
          // Pretty result card
          SimpleResultCard(
            title: 'T2D Risk Assessment',
            subtitle: 'Survey / biomarker risk',
            level: level,
            score: p,
            onOpenGemini: () => context.go('/gemini'),
          ),
          const SizedBox(height: 12),

          if (shap != null) ...[
            const Text("Top features:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...shap.entries.map((e) =>
              Text("${e.key}: ${(e.value as num).toStringAsFixed(3)}"),
            ),
          ],
        ],
      ],
    );
  }

  Widget _num(String label, TextEditingController c) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}
