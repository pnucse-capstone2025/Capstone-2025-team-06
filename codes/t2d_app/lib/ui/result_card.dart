import 'package:flutter/material.dart';

enum RiskLevel { low, mild, moderate, high, critical }

RiskLevel parseRisk(String? s, {double? score}) {
  final t = (s ?? '').toLowerCase().trim();
  if (t.contains('no dr') || t.contains('no') || t.contains('none') || t.contains('healthy')) {
    return RiskLevel.low;
  }
  if (t.contains('mild')) return RiskLevel.mild;
  if (t.contains('moderate')) return RiskLevel.moderate;
  if (t.contains('severe')) return RiskLevel.high;
  if (t.contains('proliferative')) return RiskLevel.critical;
  if (t.contains('critical')) return RiskLevel.critical;
  if (t.contains('high')) return RiskLevel.high;
  // fallback by score if provided
  final sVal = (score ?? 0).clamp(0.0, 1.0);
  if (sVal < 0.2) return RiskLevel.low;
  if (sVal < 0.4) return RiskLevel.mild;
  if (sVal < 0.6) return RiskLevel.moderate;
  if (sVal < 0.8) return RiskLevel.high;
  return RiskLevel.critical;
}

String _riskLabel(RiskLevel r) => switch (r) {
  RiskLevel.low => 'Low risk',
  RiskLevel.mild => 'Mild risk',
  RiskLevel.moderate => 'Moderate risk',
  RiskLevel.high => 'High risk',
  RiskLevel.critical => 'Critical risk',
};

Color _riskColor(RiskLevel r) => switch (r) {
  RiskLevel.low => const Color(0xFF16A34A),
  RiskLevel.mild => const Color(0xFF0EA5E9),
  RiskLevel.moderate => const Color(0xFFF59E0B),
  RiskLevel.high => const Color(0xFFEF4444),
  RiskLevel.critical => const Color(0xFFB91C1C),
};

String defaultMessage(RiskLevel r) => switch (r) {
  RiskLevel.low =>
      'Keep a healthy lifestyle. You can also try our Gemini coach for meal prep and exercise ideas.',
  RiskLevel.mild =>
      'Keep a healthy lifestyle, and check with a medical professional if you have concerns.',
  RiskLevel.moderate =>
      'Consider professional advice soon. Lifestyle improvements are recommended.',
  RiskLevel.high => 'Consult a medical professional.',
  RiskLevel.critical => 'Seek immediate medical attention.',
};

class SimpleResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final RiskLevel level;
  final double? score; // 0..1
  final VoidCallback? onOpenGemini;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const SimpleResultCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.level,
    this.score,
    this.onOpenGemini,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = ((score ?? 0) * 100).clamp(0, 100).round();
    final label = _riskLabel(level);
    final color = _riskColor(level);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _TitleBlock(title: title, subtitle: subtitle)),
            _Badge(text: label, color: color),
          ]),
          const SizedBox(height: 12),
          if (score != null) _ScoreStrip(percent: pct),
          const SizedBox(height: 8),
          Text(
            'Assessment: $label${score != null ? '  •  Score: $pct/100' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(defaultMessage(level), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: [
            if (onOpenGemini != null)
              OutlinedButton(onPressed: onOpenGemini, child: const Text('Open Gemini Coach')),
            if (onSecondary != null && (secondaryLabel ?? '').isNotEmpty)
              FilledButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ]),
        ]),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  const _TitleBlock({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2)),
      const SizedBox(height: 6),
      Text(subtitle, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: Theme.of(context).colorScheme.outlineVariant);
    return Container(
      decoration: ShapeDecoration(shape: StadiumBorder(side: border)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(.35), blurRadius: 6, spreadRadius: 1)],
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  final int percent;
  const _ScoreStrip({required this.percent});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 22,
        child: Stack(alignment: Alignment.centerLeft, children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(colors: [
                Color(0xFF16A34A), Color(0xFF0EA5E9), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFB91C1C),
              ]),
            ),
          ),
          Align(
            alignment: Alignment((percent / 50) - 1, 0),
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26, offset: Offset(0, 2))],
              ),
            ),
          ),
        ]),
      );
}
