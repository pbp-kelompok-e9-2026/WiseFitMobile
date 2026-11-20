typedef Json = Map<String, dynamic>;

class ApiUser {
  ApiUser.fromJson(Json data)
    : id = data['id'] as int,
      username = data['username'] as String,
      canAnalyze = data['can_analyze'] as bool,
      canManageReferences = data['can_manage_references'] as bool;
  final int id;
  final String username;
  final bool canAnalyze;
  final bool canManageReferences;
}

class Choice {
  Choice.fromJson(Json data)
    : value = data['value'] as String,
      label = data['label'] as String;
  final String value;
  final String label;
}

class FormOptions {
  FormOptions.fromJson(Json data)
    : choices = data.map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((entry) => Choice.fromJson(entry as Json))
              .toList(),
        ),
      );
  final Map<String, List<Choice>> choices;
  List<Choice> operator [](String key) => choices[key] ?? [];
}

class AnalysisResult {
  AnalysisResult.fromJson(Json data)
    : costPerWear = data['cost_per_wear'] as String,
      score = data['purchase_score'] as int,
      recommendation = data['recommendation_label'] as String,
      reason = data['reason'] as String,
      wearsToTarget = data['wears_to_target'] as int,
      monthsToTarget = data['months_to_target'] as int?,
      withinBudget = data['within_budget'] as bool,
      meetsTarget = data['meets_cpw_target'] as bool,
      carbonPerWear = data['carbon_per_wear'] as String?,
      breakdown = Map<String, String>.from(data['score_breakdown'] as Map);
  final String costPerWear;
  final int score;
  final String recommendation;
  final String reason;
  final int wearsToTarget;
  final int? monthsToTarget;
  final bool withinBudget;
  final bool meetsTarget;
  final String? carbonPerWear;
  final Map<String, String> breakdown;
}

const analysisFields = [
  'clothing_name',
  'category',
  'brand',
  'product_url',
  'material',
  'weight_kg',
  'existing_clothing',
  'purpose',
  'price',
  'budget',
  'expected_wears',
  'target_cpw',
  'wears_per_month',
];
const referenceFields = [
  'clothing_name',
  'category',
  'brand',
  'product_url',
  'price',
  'material',
  'weight_kg',
  'source_name',
  'notes',
  'is_published',
];

class PurchaseAnalysis {
  PurchaseAnalysis.fromJson(Json data)
    : id = data['id'] as int,
      name = data['clothing_name'] as String,
      category = data['category_label'] as String,
      inputs = {for (final key in analysisFields) key: data[key]},
      result = AnalysisResult.fromJson(data['result'] as Json),
      decision = data['decision'] as String,
      decisionLabel = data['decision_label'] as String,
      decisionNote = data['decision_note'] as String,
      carbon = data['carbon_kg_co2e'] as String?,
      carbonReference = data['carbon_reference'] as String,
      carbonScope = data['carbon_scope'] as String,
      notice = data['notice'] as String? ?? '';
  final int id;
  final String name;
  final String category;
  final Json inputs;
  final AnalysisResult result;
  final String decision;
  final String decisionLabel;
  final String decisionNote;
  final String? carbon;
  final String carbonReference;
  final String carbonScope;
  final String notice;
}

class ClothingReference {
  ClothingReference.fromJson(Json data)
    : id = data['id'] as int,
      name = data['clothing_name'] as String,
      category = data['category_label'] as String,
      price = data['price'] as String,
      source = data['source_name'] as String,
      notes = data['notes'] as String,
      published = data['is_published'] as bool,
      inputs = {for (final key in referenceFields) key: data[key]};
  final int id;
  final String name;
  final String category;
  final String price;
  final String source;
  final String notes;
  final bool published;
  final Json inputs;
  Json get analysisInitial => {
    for (final key in analysisFields)
      if (inputs.containsKey(key)) key: inputs[key],
  };
}

class ResultPage<T> {
  const ResultPage({
    required this.items,
    required this.count,
    required this.hasNext,
  });
  final List<T> items;
  final int count;
  final bool hasNext;
}

String rupiah(Object? value) {
  final number = double.tryParse(value.toString());
  if (number == null) return '—';
  final parts = number.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
  return 'Rp $whole${parts[1] == '00' ? '' : ',${parts[1]}'}';
}
