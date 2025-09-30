import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

/// GeminiService
/// - Modes:
///   1) generateMealPlan(...)            -> weekly plan + grocery list + prep tips
///   2) generateActivityProgram(...)     -> 4-week progressive + micro-workouts + daily tips
///   3) generateEducationPack(...)       -> explanations + quizzes + myth-busting
///   4) generateWeeklyReport(...)        -> summarizes tracked data + improvements
///   5) generateLifestyleTips(...)       -> general lifestyle advice section
///
/// All methods return JSON as Map<String, dynamic>.
class GeminiService {
  final GenerativeModel _model;

  GeminiService(
    String apiKey, {
    String modelName = 'gemini-1.5-flash', // fast & cheap; swap to 1.5-pro for higher quality
    double temperature = 0.8,
    double topP = 0.95,
  }) : _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: temperature,
            topP: topP,
            responseMimeType: 'application/json',
          ),
        );



  /// Multi-day weekly meal plan with grocery list & prep tips.
  ///
  /// Example:
  ///   await service.generateMealPlan(
  ///     locale: 'en',
  ///     days: 7,
  ///     mealsPerDay: 3,
  ///     kcalLimitPerDay: 1800,
  ///     preferences: ['high-fiber', 'budget-friendly'],
  ///     allergies: ['peanut'],
  ///     dietStyle: 'vegan', // 'vegan' | 'vegetarian' | 'halal' | 'low-carb' | 'balanced' | etc.
  ///   );
  Future<Map<String, dynamic>> generateMealPlan({
    required String locale,
    required int days,
    required int mealsPerDay,
    required int kcalLimitPerDay,
    List<String> preferences = const [],
    List<String> allergies = const [],
    String dietStyle = 'balanced',
    String budget = 'budget-friendly', // 'budget-friendly' | 'moderate' | 'premium'
    bool includeSnacks = false,
  }) async {
    final prompt = _systemPrompt(locale) +
        _guardrails +
        '''
TASK: Create a ${days}-day meal plan with $mealsPerDay meals per day.
Constraints:
- Total daily energy ≤ $kcalLimitPerDay kcal.
- Diet style: $dietStyle. Preferences: ${preferences.join(', ')}.
- Allergies/intolerances to avoid: ${allergies.isEmpty ? 'none' : allergies.join(', ')}.
- Budget: $budget.
- ${includeSnacks ? 'Include one snack per day if fits kcal budget.' : 'No snacks unless needed.'}
- Focus on high-fiber foods (whole grains, legumes, veg, fruit, nuts/seeds).
- Explain briefly how the plan supports T2D prevention (fiber, GI, satiety, insulin sensitivity).

Return ONLY JSON that matches the schema.
''';

    final schema = _mealPlanSchema(
      days: days,
      mealsPerDay: mealsPerDay,
      includeSnacks: includeSnacks,
    );

    final userPayload = {
      'request': 'weekly_meal_plan',
      'locale': locale,
      'days': days,
      'meals_per_day': mealsPerDay,
      'kcal_limit_per_day': kcalLimitPerDay,
      'preferences': preferences,
      'allergies': allergies,
      'diet_style': dietStyle,
      'budget': budget,
      'include_snacks': includeSnacks,
      'output_schema': schema,
    };

    final text = await _callModel(prompt, userPayload);
    return _parseJson(text);
  }

  /// Progressive 4-week walking + strength plan, plus micro-workouts and motivation.
  Future<Map<String, dynamic>> generateActivityProgram({
    required String locale,
    String level = 'beginner', // beginner | intermediate
    bool includeMicroWorkouts = true,
    int walkingDaysPerWeek = 5,
    int strengthDaysPerWeek = 2,
    String constraints = 'office-friendly, knee-sensitive',
  }) async {
    final prompt = _systemPrompt(locale) +
        _guardrails +
        '''
TASK: Create a progressive 4-week program (walking + strength) for a $level user.
- Weekly progression (intensity/volume) should be gradual and safe.
- Walking target: ~$walkingDaysPerWeek days/week.
- Strength target: ~$strengthDaysPerWeek days/week (full-body, low-impact options).
- Constraints: $constraints
- ${includeMicroWorkouts ? 'Also add 5-minute office-friendly micro-workouts to break up sitting.' : 'Micro-workouts optional.'}
- Provide a daily motivational tip.

Return ONLY JSON that matches the schema.
''';

    final schema = _activityProgramSchema(includeMicroWorkouts: includeMicroWorkouts);

    final userPayload = {
      'request': 'activity_program_4w',
      'locale': locale,
      'level': level,
      'include_micro_workouts': includeMicroWorkouts,
      'walking_days_per_week': walkingDaysPerWeek,
      'strength_days_per_week': strengthDaysPerWeek,
      'constraints': constraints,
      'output_schema': schema,
    };

    final text = await _callModel(prompt, userPayload);
    return _parseJson(text);
  }

  /// Education pack: explanations + quizzes + myth-busting.
  Future<Map<String, dynamic>> generateEducationPack({
    required String locale,
    List<String> topics = const [
      'insulin resistance',
      'dietary fiber & glycemic control',
      'benefits of strength training',
    ],
  }) async {
    final prompt = _systemPrompt(locale) +
        _guardrails +
        '''
TASK: Build an education pack for laypeople on Type 2 Diabetes prevention.
Include:
1) Short explanations (simple language) for topics: ${topics.join(', ')}.
2) A 3-question quiz for "dietary fiber & glycemic control".
3) Myth-busting: common myths about diabetes prevention with corrections.

Return ONLY JSON that matches the schema.
''';

    final schema = _educationSchema();

    final userPayload = {
      'request': 'education_pack',
      'locale': locale,
      'topics': topics,
      'output_schema': schema,
    };

    final text = await _callModel(prompt, userPayload);
    return _parseJson(text);
  }

  /// Weekly report & personalized feedback.
  ///
  /// Example `tracking`:
  /// {
  ///   "week": "2025-09-08..2025-09-14",
  ///   "weight_kg": [65.0, 65.1, 65.0, 64.9, 64.8, 64.9, 64.7],
  ///   "steps": [7200, 9800, 4500, 10000, 8100, 3000, 12000],
  ///   "exercise_min": 180,
  ///   "strength_sessions": 2,
  ///   "avg_sleep_h": 7.2,
  ///   "logged_meals": 17
  /// }
Future<Map<String, dynamic>> generateWeeklyReport({
  required String locale,
  required Map<String, dynamic> tracking,
  int targetKcalPerDay = 1800,
}) async {
  final freeText = tracking['free_text'] ?? '';

  final prompt = _systemPrompt(locale) +
      _guardrails +
      '''
TASK: Parse the following weekly health log (free text), infer key metrics (weight change, average steps, exercise adherence, sleep quality), and produce a friendly progress report for T2D prevention.

Data:
$freeText

Include in your JSON:
- summary_highlights: key wins (weight change, active days, improved habits)
- improvements_next_week: 3 concrete suggestions (specific and achievable)
- suggested_daily_schedule: morning, midday, evening tips
- encouragement: 1-2 sentences of motivational text

Consider target daily energy: $targetKcalPerDay kcal.
Return ONLY JSON that matches the schema.
''';

  final schema = _weeklyReportSchema();

  final userPayload = {
    'request': 'weekly_report_free_text',
    'locale': locale,
    'tracking_free_text': freeText,
    'target_kcal_per_day': targetKcalPerDay,
    'output_schema': schema,
  };

  final text = await _callModel(prompt, userPayload);
  return _parseJson(text);
}


  /// General lifestyle tips section (sleep, stress, NEAT, smoking, alcohol).
  Future<Map<String, dynamic>> generateLifestyleTips({
    required String locale,
    int count = 6,
  }) async {
    final prompt = _systemPrompt(locale) +
        _guardrails +
        '''
TASK: Provide $count concise lifestyle tips for T2D prevention (sleep, stress, NEAT, smoking cessation, alcohol limits, hydration).
Each tip should be 1–2 sentences max and actionable.

Return ONLY JSON that matches the schema.
''';

    final schema = _lifestyleSchema();

    final userPayload = {
      'request': 'lifestyle_tips',
      'locale': locale,
      'count': count,
      'output_schema': schema,
    };

    final text = await _callModel(prompt, userPayload);
    return _parseJson(text);
  }

  // ---------------------------
  // Internals
  // ---------------------------

  Future<String> _callModel(String systemPrompt, Map<String, dynamic> userMsg) async {
    final response = await _model.generateContent([
      // NOTE: google_generative_ai's Content only supports text/multipart.
      Content.text(systemPrompt),
      Content.text(jsonEncode(userMsg)),
    ]);

    final text = response.text ?? '';
    if (text.trim().isEmpty) {
      throw Exception('Empty response from Gemini');
    }
    return text;
  }

  Map<String, dynamic> _parseJson(String raw) {
    // Strip code fences if model added them.
    var cleaned = raw
        .replaceAll(RegExp(r'^```(json)?', multiLine: true), '')
        .replaceAll(RegExp(r'```$', multiLine: true), '')
        .trim();

    if (!cleaned.trim().startsWith('{')) {
      final match = RegExp(r'\{[\s\S]*\}$').firstMatch(cleaned);
      if (match != null) cleaned = match.group(0)!;
    }

    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to parse JSON from model: $e\n--- RAW ---\n$raw');
    }
  }

  String _systemPrompt(String locale) => '''
You are a friendly, evidence-informed wellness coach focused on Type 2 Diabetes (T2D) prevention.
- Personalize to user inputs and cultural dietary patterns.
- Keep tone supportive and practical. Avoid medical diagnosis.
- Give concise rationales (fiber, GI, insulin sensitivity, satiety, BP, lipids).
- Respond in locale: $locale.
- Return ONLY valid JSON matching the provided schema (no extra text).
''';

  String get _guardrails => '''
Safety:
- Avoid extreme diets, starvation, or excessive restriction.
- Provide low-impact options for injuries and beginners.
- Add allergy warnings and safe substitutions when relevant.
- Encourage clinician consultation for existing conditions/medications.
''';

  // ---------------------------
  // Schemas (used to shape responses)
  // ---------------------------

  Map<String, dynamic> _mealPlanSchema({
    required int days,
    required int mealsPerDay,
    required bool includeSnacks,
  }) {
    return {
      'type': 'object',
      'properties': {
        'summary': {
          'type': 'object',
          'properties': {
            'days': {'type': 'number'},
            'meals_per_day': {'type': 'number'},
            'daily_kcal_cap': {'type': 'number'},
            'diet_style': {'type': 'string'},
            'key_points': {
              'type': 'array',
              'items': {'type': 'string'}
            }
          }
        },
        'plan': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'day': {'type': 'number'},
              'meals': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'title': {'type': 'string'},
                    'approx_calories': {'type': 'number'},
                    'macros': {
                      'type': 'object',
                      'properties': {
                        'protein_g': {'type': 'number'},
                        'carbs_g': {'type': 'number'},
                        'fat_g': {'type': 'number'},
                        'fiber_g': {'type': 'number'},
                      }
                    },
                    'ingredients': {
                      'type': 'array',
                      'items': {'type': 'string'}
                    },
                    'instructions': {'type': 'string'},
                    'why_it_helps_T2D': {'type': 'string'},
                    'allergy_notes': {'type': 'string'},
                    'substitutions': {'type': 'string'},
                  },
                  'required': [
                    'title',
                    'approx_calories',
                    'ingredients',
                    'instructions',
                    'why_it_helps_T2D'
                  ]
                }
              },
              if (includeSnacks)
                'snack': {
                  'type': 'object',
                  'properties': {
                    'title': {'type': 'string'},
                    'approx_calories': {'type': 'number'}
                  }
                }
            },
            'required': ['day', 'meals']
          }
        },
        'grocery_list': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'category': {'type': 'string'}, // e.g., Produce, Grains, Protein, Dairy, Pantry
              'items': {
                'type': 'array',
                'items': {'type': 'string'}
              }
            },
            'required': ['category', 'items']
          }
        },
        'meal_prep_tips': {
          'type': 'array',
          'items': {'type': 'string'}
        }
      },
      'required': ['summary', 'plan', 'grocery_list', 'meal_prep_tips']
    };
  }

  Map<String, dynamic> _activityProgramSchema({required bool includeMicroWorkouts}) {
    return {
      'type': 'object',
      'properties': {
        'summary': {
          'type': 'object',
          'properties': {
            'weeks': {'type': 'number'},
            'level': {'type': 'string'},
            'focus': {'type': 'string'}, // e.g., aerobic base + strength
            'key_points': {
              'type': 'array',
              'items': {'type': 'string'}
            }
          }
        },
        'weeks': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'week': {'type': 'number'},
              'days': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'day': {'type': 'number'},
                    'session': {
                      'type': 'array',
                      'items': {
                        'type': 'object',
                        'properties': {
                          'name': {'type': 'string'}, // e.g., Brisk Walk, Full-body Strength
                          'type': {'type': 'string'}, // aerobic, resistance, mobility, NEAT
                          'target_intensity': {'type': 'string'}, // RPE 4–6, talk test, HR zone
                          'duration_min': {'type': 'number'},
                          'notes': {'type': 'string'},
                          'why_it_helps_T2D': {'type': 'string'},
                        },
                        'required': ['name', 'type', 'duration_min']
                      }
                    },
                    if (includeMicroWorkouts)
                      'micro_workout': {
                        'type': 'string'
                      },
                    'tip_of_the_day': {'type': 'string'}
                  },
                  'required': ['day', 'session', 'tip_of_the_day']
                }
              }
            },
            'required': ['week', 'days']
          }
        }
      },
      'required': ['summary', 'weeks']
    };
  }

  Map<String, dynamic> _educationSchema() {
    return {
      'type': 'object',
      'properties': {
        'explanations': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'topic': {'type': 'string'},
              'plain_explanation': {'type': 'string'},
            },
            'required': ['topic', 'plain_explanation']
          }
        },
        'quiz': {
          'type': 'object',
          'properties': {
            'topic': {'type': 'string'},
            'questions': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'q': {'type': 'string'},
                  'choices': {
                    'type': 'array',
                    'items': {'type': 'string'}
                  },
                  'answer': {'type': 'string'}
                },
                'required': ['q', 'choices', 'answer']
              }
            }
          },
          'required': ['topic', 'questions']
        },
        'myth_busting': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'myth': {'type': 'string'},
              'truth': {'type': 'string'}
            },
            'required': ['myth', 'truth']
          }
        }
      },
      'required': ['explanations', 'quiz', 'myth_busting']
    };
  }

  Map<String, dynamic> _weeklyReportSchema() {
    return {
      'type': 'object',
      'properties': {
        'summary_highlights': {
          'type': 'array',
          'items': {'type': 'string'}
        },
        'improvements_next_week': {
          'type': 'array',
          'items': {'type': 'string'}
        },
        'suggested_daily_schedule': {
          'type': 'object',
          'properties': {
            'morning': {'type': 'string'},
            'midday': {'type': 'string'},
            'evening': {'type': 'string'},
          }
        },
        'encouragement': {'type': 'string'}
      },
      'required': [
        'summary_highlights',
        'improvements_next_week',
        'suggested_daily_schedule',
        'encouragement'
      ]
    };
  }

  Map<String, dynamic> _lifestyleSchema() {
    return {
      'type': 'object',
      'properties': {
        'tips': {
          'type': 'array',
          'items': {'type': 'string'}
        }
      },
      'required': ['tips']
    };
  }
}
