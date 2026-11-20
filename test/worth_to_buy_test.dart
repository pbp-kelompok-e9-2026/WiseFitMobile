import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wisefit_mobile/main.dart';
import 'package:wisefit_mobile/models/worth_to_buy.dart';
import 'package:wisefit_mobile/services/worth_to_buy_api.dart';

import 'fixtures.dart';

Future<void> visible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first,
    maxScrolls: 35,
  );
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String name, String text) async {
  final finder = find.byKey(ValueKey(name));
  await visible(tester, finder);
  await tester.enterText(finder, text);
}

Future<void> choose(WidgetTester tester, String name, String label) async {
  final finder = find.byKey(ValueKey(name));
  await visible(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'standalone opens module pages without login or network requests',
    (tester) async {
      phoneSize(tester);
      var requests = 0;
      final api = WorthToBuyApi(
        client: MockClient((_) async {
          requests++;
          throw StateError('Standalone preview must not contact a server.');
        }),
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(MyApp(api: api));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Pratinjau tampilan'), findsOneWidget);
      expect(find.text('Masuk'), findsNothing);
      await tester.tap(find.text('Analisis baru'));
      await tester.pumpAndSettle();
      await fill(tester, 'clothing_name', 'Kemeja kuliah');
      await choose(tester, 'category', 'Atasan');
      await fill(tester, 'price', '300000');
      await fill(tester, 'budget', '400000');
      await choose(tester, 'existing_clothing', 'Belum ada');
      await choose(tester, 'purpose', 'Kebutuhan rutin');
      await fill(tester, 'expected_wears', '60');
      await fill(tester, 'target_cpw', '10000');
      await visible(tester, find.text('Simpan & lihat hasil'));
      await tester.tap(find.text('Simpan & lihat hasil'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Penyimpanan dan data server tersedia setelah sesi login bersama terhubung.',
        ),
        findsOneWidget,
      );
      expect(requests, 0);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Pratinjau tampilan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tampilan Analyzer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Referensi baru'));
      await tester.pumpAndSettle();
      expect(find.text('Tambah referensi'), findsOneWidget);
      expect(requests, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('revoked shared session returns to module preview', (
    tester,
  ) async {
    phoneSize(tester);
    final api = WorthToBuyApi(
      user: ApiUser.fromJson({
        'id': 1,
        'username': 'Nafisah',
        'can_analyze': true,
        'can_manage_references': false,
      }),
      sessionToken: 'shared-test-token',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/options/')) {
          return http.Response(jsonEncode(optionsData), 200);
        }
        if (request.url.path.endsWith('/analyses/')) {
          return http.Response(
            jsonEncode({
              'count': 1,
              'next': null,
              'results': [analysisData()],
            }),
            200,
          );
        }
        return http.Response('{"detail":"Invalid token."}', 401);
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(MyApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kemeja kuliah'));
    await tester.pumpAndSettle();
    await visible(tester, find.text('Perbarui estimasi karbon'));
    await tester.tap(find.text('Perbarui estimasi karbon'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pratinjau tampilan'), findsOneWidget);
    expect(find.text('Hasil analisis'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'API sends JSON, token, pagination and clears revoked session',
    () async {
      var revoke = false;
      final client = MockClient((request) async {
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['Authorization'], 'Token test-token');
        expect(request.url.queryParameters['page'], '2');
        return revoke
            ? http.Response('{"detail":"Invalid token."}', 401)
            : http.Response(
                jsonEncode({
                  'count': 13,
                  'next': null,
                  'results': [analysisData()],
                }),
                200,
              );
      });
      final api = WorthToBuyApi(
        baseUrl: 'https://example.test/',
        client: client,
        user: ApiUser.fromJson({
          'id': 1,
          'username': 'Nafisah',
          'can_analyze': true,
          'can_manage_references': false,
        }),
        sessionToken: 'test-token',
      );
      addTearDown(api.dispose);
      final page = await api.analyses(2);
      expect(page.count, 13);
      expect(page.items.single.result.costPerWear, '5000.00');
      revoke = true;
      await expectLater(api.analyses(2), throwsA(isA<ApiException>()));
      expect(api.user, isNull);
    },
  );

  testWidgets(
    'user creates, decides, edits and deletes an analysis on a phone',
    (tester) async {
      phoneSize(tester);
      final api = FakeApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(MyApp(api: api));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada analisis.'), findsOneWidget);
      await tester.tap(find.text('Analisis baru'));
      await tester.pumpAndSettle();
      await fill(tester, 'clothing_name', 'Kemeja kuliah');
      await choose(tester, 'category', 'Atasan');
      await fill(tester, 'price', '300000');
      await fill(tester, 'budget', '400000');
      await choose(tester, 'existing_clothing', 'Belum ada');
      await choose(tester, 'purpose', 'Kebutuhan rutin');
      await fill(tester, 'expected_wears', '60');
      await fill(tester, 'target_cpw', '10000');
      await visible(tester, find.text('Simpan & lihat hasil'));
      await tester.tap(find.text('Simpan & lihat hasil'));
      await tester.pumpAndSettle();
      expect(api.submitted!['clothing_name'], 'Kemeja kuliah');
      expect(find.text('100/100'), findsOneWidget);
      await visible(tester, find.text('Simpan keputusan'));
      await tester.tap(find.text('Simpan keputusan'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beli dengan rencana pemakaian').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Untuk kuliah');
      await tester.tap(find.text('Simpan keputusan'));
      await tester.pumpAndSettle();
      expect(api.saved!.decision, 'buy');
      await tester.tap(find.byTooltip('Edit analisis'));
      await tester.pumpAndSettle();
      await fill(tester, 'price', '350000');
      await visible(tester, find.text('Simpan & lihat hasil'));
      await tester.tap(find.text('Simpan & lihat hasil'));
      await tester.pumpAndSettle();
      expect(api.submitted!['price'], '350000');
      expect(api.saved!.decision, 'undecided');
      await tester.tap(find.byTooltip('Hapus analisis'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(api.saved, isNull);
      expect(find.text('Belum ada analisis.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('catalogue prefills clothing while personal inputs stay empty', (
    tester,
  ) async {
    phoneSize(tester);
    final api = FakeApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(MyApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kemeja referensi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gunakan untuk analisis'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('clothing_name')))
          .controller!
          .text,
      'Kemeja referensi',
    );
    await visible(tester, find.byKey(const ValueKey('budget')));
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('budget')))
          .controller!
          .text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('analyzer withdraws publication and edits references', (
    tester,
  ) async {
    phoneSize(tester);
    final api = FakeApi(analyzer: true);
    addTearDown(api.dispose);
    await tester.pumpWidget(MyApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('Analisis baru'), findsNothing);
    expect(find.text('Riwayat'), findsNothing);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tarik dari katalog'));
    await tester.pumpAndSettle();
    expect(api.published, isFalse);
    await tester.tap(find.text('Kemeja referensi'));
    await tester.pumpAndSettle();
    await fill(tester, 'clothing_name', 'Kemeja diperbarui');
    await visible(tester, find.text('Simpan referensi'));
    await tester.tap(find.text('Simpan referensi'));
    await tester.pumpAndSettle();
    expect(api.submitted!['clothing_name'], 'Kemeja diperbarui');
    expect(api.submitted!['is_published'], isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed list offers a working retry', (tester) async {
    final api = FakeApi()..fail = true;
    addTearDown(api.dispose);
    await tester.pumpWidget(MyApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('Koneksi terputus.'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada analisis.'), findsOneWidget);
  });
}
