import 'package:flutter_test/flutter_test.dart';
import 'package:wisefit_mobile/models/worth_to_buy.dart';
import 'package:wisefit_mobile/services/worth_to_buy_api.dart';

void main() {
  const runLive = bool.fromEnvironment('RUN_LIVE_API_TESTS');
  test('Flutter talks to real Django: role, catalogue, CRUD, decision using shared sessions', () async {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8765',
    );
    const userToken = String.fromEnvironment('USER_API_TOKEN');
    const analyzerToken = String.fromEnvironment('ANALYZER_API_TOKEN');
    expect(userToken, isNotEmpty);
    expect(analyzerToken, isNotEmpty);
    final user = WorthToBuyApi(
      baseUrl: baseUrl,
      sessionToken: userToken,
      user: ApiUser.fromJson({
        'id': 1,
        'username': 'smoke_user',
        'can_analyze': true,
        'can_manage_references': false,
      }),
    );
    final analyzer = WorthToBuyApi(
      baseUrl: baseUrl,
      sessionToken: analyzerToken,
      user: ApiUser.fromJson({
        'id': 2,
        'username': 'smoke_analyzer',
        'can_analyze': false,
        'can_manage_references': true,
      }),
    );
    addTearDown(user.dispose);
    addTearDown(analyzer.dispose);
    expect(analyzer.user!.canManageReferences, isTrue);
    await expectLater(analyzer.analyses(1), throwsA(isA<ApiException>()));
    final reference = await analyzer.saveReference({
      'clothing_name': 'Smoke kemeja',
      'category': 'top',
      'price': '300000',
      'source_name': 'Uji integrasi lokal',
      'is_published': false,
    });
    await analyzer.publish(reference.id, true);
    final options = await user.options();
    expect(
      options['categories'].any((choice) => choice.value == 'top'),
      isTrue,
    );
    final catalogue = await user.references(
      workspace: false,
      query: 'Smoke kemeja',
    );
    expect(catalogue.items.any((item) => item.id == reference.id), isTrue);
    final input = {
      ...reference.analysisInitial,
      'budget': '400000',
      'expected_wears': '60',
      'target_cpw': '10000',
      'existing_clothing': 'none',
      'purpose': 'routine',
    };
    final created = await user.saveAnalysis(input);
    expect(created.result.costPerWear, '5000.00');
    expect(created.result.score, 100);
    final decided = await user.decide(created.id, 'buy', 'Hasil uji HTTP');
    expect(decided.decision, 'buy');
    final edited = await user.saveAnalysis({
      ...input,
      'price': '600000',
    }, id: created.id);
    expect(edited.result.costPerWear, '10000.00');
    expect(edited.decision, 'undecided');
    expect((await user.analysis(created.id)).id, created.id);
    expect(
      (await user.analyses(1)).items.any((item) => item.id == created.id),
      isTrue,
    );
    await user.deleteAnalysis(created.id);
    await expectLater(user.analysis(created.id), throwsA(isA<ApiException>()));
    await analyzer.deleteReference(reference.id);
  }, skip: !runLive);
}
