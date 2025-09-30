// lib/pages/dfu_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../services/model_service.dart' as api;
import '../ui/result_card.dart'; // your simple card with parseRisk + RiskLevel

class DfuPage extends StatefulWidget { const DfuPage({super.key}); @override State<DfuPage> createState()=>_DfuPageState(); }

class _DfuPageState extends State<DfuPage> {
  Map<String,dynamic>? res; String? err; Uint8List? picked;

  Future<void> _choose() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if(r!=null && r.files.single.bytes!=null){
      setState(()=>picked=r.files.single.bytes);
      try{
        res = await api.predictImage("dfu", r.files.single.bytes!, r.files.single.name);
        setState((){});
      }catch(e){ setState(()=>err=e.toString()); }
    }
  }

  @override
  Widget build(BuildContext context){
    final probs = (res?['probs'] as Map?)?.cast<String, dynamic>();
    final topClass = (res?['top_class'] ?? '').toString();
    final topProb  = (res?['top_prob'] as num?)?.toDouble();

    
    final isRegularWound = topClass.toLowerCase().contains('wound') &&
                           !topClass.toLowerCase().contains('ulcer');
    final level = isRegularWound ? RiskLevel.low : parseRisk(topClass, score: topProb);
    final subtitle = isRegularWound ? 'Looks like a regular wound'
                                    : 'Photo-based screening';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          FilledButton(onPressed:_choose, child: const Text("Upload DFU image")),
          if(err!=null)...[const SizedBox(height:8), Text(err!, style: const TextStyle(color: Colors.red))],

          if(res!=null)...[
            const SizedBox(height:12),
            SimpleResultCard(
              title: 'DFU Screening Result',
              subtitle: subtitle,
              level: level,
              score: topProb,
              onOpenGemini: () => context.go('/gemini'),
            ),
            const SizedBox(height:12),

            if(probs!=null) _probsList(probs),
            const SizedBox(height:12),
            if(res!["explanation_b64"]!=null)
              Image.memory(Uri.parse(res!["explanation_b64"]).data!.contentAsBytes()),
          ]
        ],
      ),
    );
  }

  Widget _probsList(Map<String,dynamic> probs){
    final entries = probs.entries.toList()
      ..sort((a,b)=> (b.value as num).compareTo(a.value as num));
    return Column(
      children: entries.map((e){
        final p = (e.value as num).toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width:120, child: Text(e.key)),
              Expanded(child: LinearProgressIndicator(value: p, minHeight: 10)),
              const SizedBox(width:8),
              SizedBox(width:50, child: Text("${(p*100).toStringAsFixed(1)}%")),
            ],
          ),
        );
      }).toList(),
    );
  }
}
