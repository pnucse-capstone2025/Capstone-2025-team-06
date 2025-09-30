import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class GeminiPage extends StatefulWidget {
  const GeminiPage({super.key});
  @override
  State<GeminiPage> createState() => _GeminiPageState();
}

class _GeminiPageState extends State<GeminiPage> {
  // Using your hardcoded key from the demo:
  static const String _apiKey = "AIzaSyAuyKdTMrn0-ZgESbHgNYEK16hZqKpluqU";

  // ---- Meal Plan inputs ----
  final _mealDaysCtrl = TextEditingController(text: '7');
  final _mealsPerDayCtrl = TextEditingController(text: '3');
  final _kcalCtrl = TextEditingController(text: '1800');
  final _prefsCtrl = TextEditingController(text: 'high-fiber, budget-friendly');
  final _allergiesCtrl = TextEditingController(text: '');
  String _dietStyle = 'balanced';
  bool _includeSnacks = false;

  // ---- Activity inputs ----
  String _level = 'beginner';
  final _walkingDaysCtrl = TextEditingController(text: '5');
  final _strengthDaysCtrl = TextEditingController(text: '2');
  final _constraintsCtrl = TextEditingController(text: 'office-friendly, knee-sensitive');
  bool _includeMicro = true;

  // ---- Education inputs ----
  final List<String> _topics = [
    'insulin resistance',
    'dietary fiber & glycemic control',
    'benefits of strength training',
  ];

  // ---- Weekly report inputs ----
  final _trackingTextCtrl = TextEditingController(
    text: '''Week: 2025-09-08..2025-09-14
Weight (kg): 65, 65.1, 65, 64.9, 64.8, 64.9, 64.7
Steps: 7200, 9800, 4500, 10000, 8100, 3000, 12000
Exercise minutes: 180
Strength sessions: 2
Average sleep (h): 7.2
Logged meals: 17''',
  );
  final _targetKcalCtrl = TextEditingController(text: '1800');

  // ---- Lifestyle tips ----
  final _tipsCountCtrl = TextEditingController(text: '6');

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  // ---------------- Actions ----------------
  Future<void> _genMealPlan() async {
    await _run(asyncFn: () async {
      final service = GeminiService(_apiKey);
      _result = await service.generateMealPlan(
        locale: 'en',
        days: int.tryParse(_mealDaysCtrl.text) ?? 7,
        mealsPerDay: int.tryParse(_mealsPerDayCtrl.text) ?? 3,
        kcalLimitPerDay: int.tryParse(_kcalCtrl.text) ?? 1800,
        preferences: _splitList(_prefsCtrl.text),
        allergies: _splitList(_allergiesCtrl.text),
        dietStyle: _dietStyle,
        includeSnacks: _includeSnacks,
      );
    });
  }

  Future<void> _genActivityProgram() async {
    await _run(asyncFn: () async {
      final service = GeminiService(_apiKey);
      _result = await service.generateActivityProgram(
        locale: 'en',
        level: _level,
        includeMicroWorkouts: _includeMicro,
        walkingDaysPerWeek: int.tryParse(_walkingDaysCtrl.text) ?? 5,
        strengthDaysPerWeek: int.tryParse(_strengthDaysCtrl.text) ?? 2,
        constraints: _constraintsCtrl.text.trim(),
      );
    });
  }

  Future<void> _genEducationPack() async {
    await _run(asyncFn: () async {
      final service = GeminiService(_apiKey);
      _result = await service.generateEducationPack(locale: 'en', topics: _topics);
    });
  }

  Future<void> _genWeeklyReport() async {
    await _run(asyncFn: () async {
      final service = GeminiService(_apiKey);
      _result = await service.generateWeeklyReport(
        locale: 'en',
        tracking: {'free_text': _trackingTextCtrl.text},
        targetKcalPerDay: int.tryParse(_targetKcalCtrl.text) ?? 1800,
      );
    });
  }

  Future<void> _genLifestyleTips() async {
    await _run(asyncFn: () async {
      final service = GeminiService(_apiKey);
      _result = await service.generateLifestyleTips(
        locale: 'en',
        count: int.tryParse(_tipsCountCtrl.text) ?? 6,
      );
    });
  }

  Future<void> _run({required Future<void> Function() asyncFn}) async {
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      await asyncFn();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() { _loading = false; });
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('T2D Lifestyle Coach (Gemini)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Weekly Meal Plan'),
            Row(children: [
              Expanded(child: _numField(_mealDaysCtrl, 'Days')),
              const SizedBox(width: 8),
              Expanded(child: _numField(_mealsPerDayCtrl, 'Meals/day')),
              const SizedBox(width: 8),
              Expanded(child: _numField(_kcalCtrl, 'Daily kcal cap')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _textField(_prefsCtrl, 'Preferences')),
              const SizedBox(width: 8),
              Expanded(child: _textField(_allergiesCtrl, 'Allergies')),
            ]),
            Row(children: [
              Expanded(child: _dietDropdown()),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include snacks'),
                  value: _includeSnacks,
                  onChanged: (v) => setState(() => _includeSnacks = v),
                ),
              ),
            ]),
            FilledButton.icon(
              onPressed: _loading ? null : _genMealPlan,
              icon: const Icon(Icons.restaurant),
              label: const Text('Generate Meal Plan'),
            ),

            const Divider(height: 32),

            _sectionTitle('Activity Program (4 weeks)'),
            Row(children: [
              Expanded(child: _levelDropdown()),
              const SizedBox(width: 8),
              Expanded(child: _numField(_walkingDaysCtrl, 'Walking days/week')),
              const SizedBox(width: 8),
              Expanded(child: _numField(_strengthDaysCtrl, 'Strength days/week')),
            ]),
            const SizedBox(height: 8),
            _textField(_constraintsCtrl, 'Constraints'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include micro-workouts'),
              value: _includeMicro,
              onChanged: (v) => setState(() => _includeMicro = v),
            ),
            FilledButton.icon(
              onPressed: _loading ? null : _genActivityProgram,
              icon: const Icon(Icons.fitness_center),
              label: const Text('Generate Activity Program'),
            ),

            const Divider(height: 32),

            _sectionTitle('Education & Engagement'),
            Wrap(spacing: 8, children: _topics.map((t) => Chip(label: Text(t))).toList()),
            FilledButton.icon(
              onPressed: _loading ? null : _genEducationPack,
              icon: const Icon(Icons.menu_book),
              label: const Text('Generate Education Pack'),
            ),

            const Divider(height: 32),

            _sectionTitle('Weekly Report (free text input)'),
            _multilineField(_trackingTextCtrl, 'Enter weekly data as text'),
            const SizedBox(height: 8),
            _numField(_targetKcalCtrl, 'Target kcal/day'),
            FilledButton.icon(
              onPressed: _loading ? null : _genWeeklyReport,
              icon: const Icon(Icons.bar_chart),
              label: const Text('Generate Weekly Report'),
            ),

            const Divider(height: 32),

            _sectionTitle('Lifestyle Tips'),
            Row(children: [
              Expanded(child: _numField(_tipsCountCtrl, 'How many tips?')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _loading ? null : _genLifestyleTips,
                icon: const Icon(Icons.lightbulb),
                label: const Text('Generate Tips'),
              ),
            ]),

            const SizedBox(height: 16),

            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),

            if (_result != null) ...[
              const SizedBox(height: 8),
              _prettyRenderer(_result!),
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('Raw JSON (debug)'),
                children: [
                  SelectableText(const JsonEncoder.withIndent('  ').convert(_result)),
                  const SizedBox(height: 12),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }

  // ----------------  renderers ----------------
  Widget _prettyRenderer(Map<String, dynamic> data) {
    if (data.containsKey('plan') && data.containsKey('grocery_list')) {
      return _renderMealPlan(data);
    } else if (data.containsKey('weeks') && data.containsKey('summary')) {
      return _renderActivityProgram(data);
    } else if (data.containsKey('explanations') && data.containsKey('quiz')) {
      return _renderEducationPack(data);
    } else if (data.containsKey('summary_highlights') &&
        data.containsKey('suggested_daily_schedule')) {
      return _renderWeeklyReport(data);
    } else if (data.containsKey('tips')) {
      return _renderLifestyleTips(data);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text('Unknown format. Showing raw JSON above.'),
      ),
    );
  }

  Widget _renderMealPlan(Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final plan = (data['plan'] as List?) ?? [];
    final grocery = (data['grocery_list'] as List?) ?? [];
    final tips = (data['meal_prep_tips'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meal Plan Summary', style: _h2),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    if (summary['days'] != null) _chip('${summary['days']} days'),
                    if (summary['meals_per_day'] != null) _chip('${summary['meals_per_day']} meals/day'),
                    if (summary['daily_kcal_cap'] != null) _chip('≤ ${summary['daily_kcal_cap']} kcal/day'),
                    if (summary['diet_style'] != null) _chip('${summary['diet_style']}'),
                  ]),
                  if (summary['key_points'] is List)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Key points:', style: TextStyle(fontWeight: FontWeight.w600)),
                          ...List<String>.from(summary['key_points']).map((e) => Text('• $e')),
                        ],
                      ),
                    )
                ],
              ),
            ),
          ),
        ...plan.map((d) {
          final meals = (d['meals'] as List?) ?? [];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Day ${d['day']}', style: _h2),
                const SizedBox(height: 6),
                ...meals.map((m) => _mealTile(m as Map<String, dynamic>)).toList(),
                if (d['snack'] != null) ...[
                  const SizedBox(height: 8),
                  const Text('Snack', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${d['snack']['title']} (~${d['snack']['approx_calories']} kcal)'),
                ]
              ]),
            ),
          );
        }),
        if (grocery.isNotEmpty)
          ExpansionTile(
            title: const Text('Grocery List'),
            children: [
              ...grocery.map((g) {
                final items = List<String>.from(g['items'] ?? []);
                return ListTile(
                  title: Text(g['category'] ?? 'Items'),
                  subtitle: Text(items.join(', ')),
                );
              })
            ],
          ),
        if (tips.isNotEmpty)
          ExpansionTile(
            title: const Text('Meal Prep Tips'),
            children: tips.map((t) => ListTile(title: Text(t.toString()))).toList(),
          )
      ],
    );
  }

  Widget _mealTile(Map<String, dynamic> meal) {
    final macros = (meal['macros'] as Map?) ?? {};
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meal['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (meal['approx_calories'] != null) _chip('~${meal['approx_calories']} kcal'),
            if (macros['protein_g'] != null) _chip('P ${macros['protein_g']}g'),
            if (macros['carbs_g'] != null) _chip('C ${macros['carbs_g']}g'),
            if (macros['fat_g'] != null) _chip('F ${macros['fat_g']}g'),
            if (macros['fiber_g'] != null) _chip('Fiber ${macros['fiber_g']}g'),
          ]),
          const SizedBox(height: 4),
          if (meal['ingredients'] is List) ...[
            const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.w600)),
            ...List<String>.from(meal['ingredients']).map((e) => Text('• $e')),
          ],
          const SizedBox(height: 4),
          if (meal['instructions'] != null) Text('Instructions: ${meal['instructions']}'),
          if (meal['why_it_helps_T2D'] != null)
            Text('Why it helps: ${meal['why_it_helps_T2D']}'),
          if (meal['substitutions'] != null && (meal['substitutions'] as String).trim().isNotEmpty)
            Text('Substitutions: ${meal['substitutions']}'),
          if (meal['allergy_notes'] != null && (meal['allergy_notes'] as String).trim().isNotEmpty)
            Text('Allergy notes: ${meal['allergy_notes']}'),
        ],
      ),
    );
  }

  Widget _renderActivityProgram(Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final weeks = (data['weeks'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Program Summary', style: _h2),
                const SizedBox(height: 6),
                if (summary['focus'] != null) Text('Focus: ${summary['focus']}'),
                Wrap(spacing: 8, children: [
                  if (summary['weeks'] != null) _chip('${summary['weeks']} weeks'),
                  if (summary['level'] != null) _chip('${summary['level']}'),
                ]),
                if (summary['key_points'] is List)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Key points:', style: TextStyle(fontWeight: FontWeight.w600)),
                        ...List<String>.from(summary['key_points']).map((e) => Text('• $e')),
                      ],
                    ),
                  )
              ]),
            ),
          ),
        ...weeks.map((w) {
          final days = (w['days'] as List?) ?? [];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Week ${w['week']}', style: _h2),
                const SizedBox(height: 6),
                ...days.map((d) => _daySessions(d as Map<String, dynamic>)).toList(),
              ]),
            ),
          );
        })
      ],
    );
  }

  Widget _daySessions(Map<String, dynamic> day) {
    final sessions = (day['session'] as List?) ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Day ${day['day']}', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ...sessions.map((s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.run_circle_outlined),
              title: Text(s['name'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, children: [
                    if (s['type'] != null) _chip(s['type']),
                    if (s['duration_min'] != null) _chip('${s['duration_min']} min'),
                    if (s['target_intensity'] != null) _chip('Intensity: ${s['target_intensity']}'),
                  ]),
                  if (s['why_it_helps_T2D'] != null) Text('Why: ${s['why_it_helps_T2D']}'),
                  if (s['notes'] != null) Text('Notes: ${s['notes']}'),
                ],
              ),
            )),
        if (day['micro_workout'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text('Micro-workout: ${day['micro_workout']}'),
          ),
        if (day['tip_of_the_day'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text('Tip: ${day['tip_of_the_day']}'),
          ),
      ]),
    );
  }

  Widget _renderEducationPack(Map<String, dynamic> data) {
    final explanations = (data['explanations'] as List?) ?? [];
    final quiz = (data['quiz'] as Map<String, dynamic>?);
    final myths = (data['myth_busting'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (explanations.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explanations', style: _h2),
                  const SizedBox(height: 6),
                  ...explanations.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['topic'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(e['plain_explanation'] ?? ''),
                        ],
                      ),
                    );
                  })
                ],
              ),
            ),
          ),
        if (quiz != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quiz: ${quiz['topic'] ?? ''}', style: _h2),
                  const SizedBox(height: 6),
                  ...List<Map<String, dynamic>>.from(quiz['questions'] ?? []).asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final q = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$idx) ${q['q'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ...List<String>.from(q['choices'] ?? []).map((c) => Text('• $c')),
                        Text('Answer: ${q['answer'] ?? ''}', style: const TextStyle(color: Colors.teal)),
                      ]),
                    );
                  })
                ],
              ),
            ),
          ),
        if (myths.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Myth-busting', style: _h2),
                const SizedBox(height: 6),
                ...myths.map((m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Myth: ${m['myth'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Truth: ${m['truth'] ?? ''}', style: const TextStyle(color: Colors.teal)),
                      ]),
                    ))
              ]),
            ),
          ),
      ],
    );
  }

  Widget _renderWeeklyReport(Map<String, dynamic> data) {
    final highlights = (data['summary_highlights'] as List?) ?? [];
    final improvements = (data['improvements_next_week'] as List?) ?? [];
    final sched = (data['suggested_daily_schedule'] as Map<String, dynamic>?) ?? {};
    final encouragement = data['encouragement']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (highlights.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Highlights', style: _h2),
                const SizedBox(height: 6),
                ...highlights.map((e) => Text('• $e')),
              ]),
            ),
          ),
        if (improvements.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Improvements for Next Week', style: _h2),
                const SizedBox(height: 6),
                ...improvements.map((e) => Text('• $e')),
              ]),
            ),
          ),
        if (sched.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Suggested Daily Schedule', style: _h2),
                const SizedBox(height: 6),
                if (sched['morning'] != null) Text('• Morning: ${sched['morning']}'),
                if (sched['midday'] != null) Text('• Midday: ${sched['midday']}'),
                if (sched['evening'] != null) Text('• Evening: ${sched['evening']}'),
              ]),
            ),
          ),
        if (encouragement != null)
          Card(
            color: Colors.teal[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(encouragement, style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          )
      ],
    );
  }

  Widget _renderLifestyleTips(Map<String, dynamic> data) {
    final tips = (data['tips'] as List?) ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Lifestyle Tips', style: _h2),
          const SizedBox(height: 6),
          ...tips.map((t) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6.0, right: 6),
                    child: Icon(Icons.check_circle_outline, size: 18),
                  ),
                  Expanded(child: Text(t.toString())),
                ],
              ))
        ]),
      ),
    );
  }

  // ---------------- Helpers ----------------
  final TextStyle _h2 = const TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: _h2),
      );

  Widget _numField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(),
        decoration: InputDecoration(labelText: label),
      );

  Widget _textField(TextEditingController c, String label) => TextField(
        controller: c,
        decoration: InputDecoration(labelText: label),
      );

  Widget _multilineField(TextEditingController c, String label) => TextField(
        controller: c,
        minLines: 4,
        maxLines: 8,
        decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        ),
      );


  Widget _dietDropdown() => DropdownButtonFormField<String>(
        value: _dietStyle,
        decoration: const InputDecoration(labelText: 'Diet style'),
        items: const [
          DropdownMenuItem(value: 'balanced', child: Text('Balanced')),
          DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
          DropdownMenuItem(value: 'vegetarian', child: Text('Vegetarian')),
          DropdownMenuItem(value: 'halal', child: Text('Halal')),
          DropdownMenuItem(value: 'low-carb', child: Text('Low-carb')),
          DropdownMenuItem(value: 'mediterranean', child: Text('Mediterranean')),
        ],
        onChanged: (v) => setState(() => _dietStyle = v ?? 'balanced'),
      );

  Widget _levelDropdown() => DropdownButtonFormField<String>(
        value: _level,
        decoration: const InputDecoration(labelText: 'Level'),
        items: const [
          DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
          DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
        ],
        onChanged: (v) => setState(() => _level = v ?? 'beginner'),
      );

  Widget _chip(String text) => Chip(label: Text(text));

  List<String> _splitList(String s) =>
      s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}
