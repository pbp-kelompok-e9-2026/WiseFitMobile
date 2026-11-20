import 'package:wisefit_mobile/models/worth_to_buy.dart';
import 'package:wisefit_mobile/services/worth_to_buy_api.dart';

final optionsData = <String, dynamic>{
  'categories': [
    {'value': 'top', 'label': 'Atasan'},
  ],
  'existing_clothing': [
    {'value': 'none', 'label': 'Belum ada'},
  ],
  'purposes': [
    {'value': 'routine', 'label': 'Kebutuhan rutin'},
  ],
  'materials': [
    {'value': 'cotton', 'label': 'Cotton'},
  ],
  'decisions': [
    {'value': 'undecided', 'label': 'Belum diputuskan'},
    {'value': 'buy', 'label': 'Beli dengan rencana pemakaian'},
  ],
};

Json analysisData([Json overrides = const {}]) => {
  'id': 1,
  'clothing_name': 'Kemeja kuliah',
  'category': 'top',
  'category_label': 'Atasan',
  'brand': '',
  'product_url': '',
  'material': '',
  'weight_kg': null,
  'existing_clothing': 'none',
  'purpose': 'routine',
  'price': '300000.00',
  'budget': '400000.00',
  'expected_wears': 60,
  'target_cpw': '10000.00',
  'wears_per_month': null,
  'decision': 'undecided',
  'decision_label': 'Belum diputuskan',
  'decision_note': '',
  'carbon_kg_co2e': null,
  'carbon_reference': '',
  'carbon_scope': '',
  'result': {
    'cost_per_wear': '5000.00',
    'purchase_score': 100,
    'recommendation_label': 'Beli dengan rencana pemakaian',
    'reason': 'Sesuai budget dan target biaya per pakai.',
    'wears_to_target': 30,
    'months_to_target': null,
    'within_budget': true,
    'meets_cpw_target': true,
    'carbon_per_wear': null,
    'score_breakdown': {
      'cost_per_wear': '40.00',
      'budget': '30.00',
      'existing_clothing': '20.00',
      'purpose': '10.00',
    },
  },
  ...overrides,
};

Json referenceData([Json overrides = const {}]) => {
  'id': 1,
  'clothing_name': 'Kemeja referensi',
  'category': 'top',
  'category_label': 'Atasan',
  'brand': '',
  'product_url': '',
  'price': '300000.00',
  'material': '',
  'weight_kg': null,
  'source_name': 'Katalog merek',
  'notes': '',
  'is_published': true,
  ...overrides,
};

class FakeApi extends WorthToBuyApi {
  FakeApi({bool analyzer = false}) {
    user = ApiUser.fromJson({
      'id': 1,
      'username': 'Nafisah',
      'can_analyze': !analyzer,
      'can_manage_references': analyzer,
    });
  }
  PurchaseAnalysis? saved;
  Json? submitted;
  bool fail = false;
  bool published = true;

  @override
  Future<FormOptions> options() async => FormOptions.fromJson(optionsData);
  @override
  Future<ResultPage<PurchaseAnalysis>> analyses(int page) async {
    if (fail) throw const ApiException('Koneksi terputus.');
    return ResultPage(
      items: saved == null ? [] : [saved!],
      count: saved == null ? 0 : 1,
      hasNext: false,
    );
  }

  @override
  Future<PurchaseAnalysis> saveAnalysis(Json values, {int? id}) async {
    submitted = values;
    return saved = PurchaseAnalysis.fromJson(
      analysisData({
        ...values,
        'expected_wears': int.parse(values['expected_wears'].toString()),
      }),
    );
  }

  @override
  Future<PurchaseAnalysis> decide(int id, String decision, String note) async =>
      saved = PurchaseAnalysis.fromJson(
        analysisData({
          ...saved!.inputs,
          'decision': decision,
          'decision_note': note,
          'decision_label': 'Beli dengan rencana pemakaian',
        }),
      );
  @override
  Future<void> deleteAnalysis(int id) async {
    saved = null;
  }

  @override
  Future<ResultPage<ClothingReference>> references({
    required bool workspace,
    int page = 1,
    String query = '',
    String category = '',
    String status = '',
  }) async => ResultPage(
    items: [
      ClothingReference.fromJson(referenceData({'is_published': published})),
    ],
    count: 1,
    hasNext: false,
  );
  @override
  Future<ClothingReference> publish(int id, bool value) async {
    published = value;
    return ClothingReference.fromJson(referenceData({'is_published': value}));
  }

  @override
  Future<ClothingReference> saveReference(Json values, {int? id}) async {
    submitted = values;
    return ClothingReference.fromJson(referenceData(values));
  }
}
