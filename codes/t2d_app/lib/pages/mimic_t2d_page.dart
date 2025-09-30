import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/model_service.dart' as api;
import '../ui/result_card.dart';

class MimicT2DPage extends StatefulWidget {
  const MimicT2DPage({super.key});
  @override
  State<MimicT2DPage> createState() => _MimicT2DPageState();
}

class _MimicT2DPageState extends State<MimicT2DPage> {
  final a1c = TextEditingController(text: "6.2");
  final glu = TextEditingController(text: "118");
  final tc  = TextEditingController(text: "190");
  final hdl = TextEditingController(text: "50");
  final ldl = TextEditingController(text: "120");
  final tg  = TextEditingController(text: "160");

  Map<String, dynamic>? res;
  String? err;

  Future<void> _predict() async {
    try {
      final r = await api.predictTabular("mimic_t2d", {
        "hba1c_first": double.tryParse(a1c.text),
        "glucose_first": double.tryParse(glu.text),
        "chol_total_first": double.tryParse(tc.text),
        "chol_hdl_first": double.tryParse(hdl.text),
        "chol_ldl_first": double.tryParse(ldl.text),
        "triglycerides_first": double.tryParse(tg.text),
      });
      setState(() { res = r; err = null; });
    } catch (e) { setState(() { err = e.toString(); res = null; }); }
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
        Wrap(spacing: 10, runSpacing: 10, children: [
          _num("HbA1c", a1c), _num("Glucose", glu), _num("Total Chol", tc),
          _num("HDL", hdl), _num("LDL", ldl), _num("Triglycerides", tg),
        ]),
        const SizedBox(height: 12),
        FilledButton(onPressed: _predict, child: const Text("Predict")),
        const SizedBox(height: 12),
        if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),

        if (res != null) ...[
          SimpleResultCard(
            title: 'Clinical Risk Estimate',
            subtitle: 'EHR-derived signals',
            level: level,
            score: p,
            onOpenGemini: () => context.go('/gemini'),
          ),
          const SizedBox(height: 12),
          if (shap != null) ...[
            const Text("Top features:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...shap.entries.map((e) => Text("${e.key}: ${(e.value as num).toStringAsFixed(3)}")),
          ],
        ],
      ],
    );
  }

  Widget _num(String label, TextEditingController c) =>
      SizedBox(width: 160, child: TextField(controller: c, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label)));
}
