import 'package:flutter/material.dart';

import '../models/worth_to_buy.dart';
import '../services/worth_to_buy_api.dart';
import '../widgets/feedback.dart';
import 'analysis_detail_screen.dart';
import 'garment_form_screen.dart';
import 'carbon_footprint/carbon_footprint_home_page.dart';

class WorthToBuyScreen extends StatefulWidget {
  const WorthToBuyScreen({super.key, required this.api});
  final WorthToBuyApi api;
  @override
  State<WorthToBuyScreen> createState() => _WorthToBuyScreenState();
}

class _WorthToBuyScreenState extends State<WorthToBuyScreen> {
  final search = TextEditingController();
  int tab = 0, page = 1;
  String query = '', category = '', status = '';
  bool busy = false;
  bool previewAnalyzer = false;
  FormOptions? options;
  late Future<ResultPage<dynamic>> future;
  List<String> get tabs => [
    if (widget.api.user?.canAnalyze ?? !previewAnalyzer) 'Riwayat',
    if (widget.api.user?.canAnalyze ?? !previewAnalyzer) 'Katalog',
    if (widget.api.user?.canManageReferences ?? previewAnalyzer) 'Referensi',
  ];
  bool get history => tabs[tab] == 'Riwayat';
  bool get workspace => tabs[tab] == 'Referensi';
  @override
  void initState() {
    super.initState();
    future = fetch();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<ResultPage<dynamic>> fetch() async {
    options ??= await widget.api.options();
    if (!widget.api.hasSession) {
      return const ResultPage(items: [], count: 0, hasNext: false);
    }
    if (history) return widget.api.analyses(page);
    return widget.api.references(
      workspace: workspace,
      page: page,
      query: query,
      category: category,
      status: status,
    );
  }

  void reload({bool reset = false}) => setState(() {
    if (reset) page = 1;
    future = fetch();
  });

  Future<void> openForm({
    PurchaseAnalysis? analysis,
    ClothingReference? reference,
    bool fromCatalogue = false,
  }) async {
    final result = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (_) => GarmentFormScreen(
          api: widget.api,
          reference: workspace && !fromCatalogue,
          id: fromCatalogue ? null : analysis?.id ?? reference?.id,
          initial:
              analysis?.inputs ??
              (fromCatalogue
                  ? reference?.analysisInitial
                  : reference?.inputs) ??
              {},
        ),
      ),
    );
    if (!mounted || result == null) return;
    if (result is PurchaseAnalysis) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AnalysisDetailScreen(api: widget.api, initial: result),
        ),
      );
      if (!mounted) return;
    }
    reload(reset: true);
  }

  Future<void> referenceAction(ClothingReference item, String action) async {
    if (action == 'edit') {
      await openForm(reference: item);
      return;
    }
    if (action == 'delete' &&
        (!await confirmDelete(context, item.name) || !mounted)) {
      return;
    }
    setState(() {
      busy = true;
    });
    try {
      if (action == 'delete') {
        await widget.api.deleteReference(item.id);
      } else {
        await widget.api.publish(item.id, !item.published);
      }
      if (mounted) {
        showMessage(
          context,
          action == 'delete'
              ? 'Referensi dihapus.'
              : 'Status publikasi diperbarui.',
        );
        reload(reset: true);
      }
    } on ApiException catch (error) {
      if (mounted) showMessage(context, error.message);
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> openReference(ClothingReference item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('${item.category} · ${rupiah(item.price)}'),
              const SizedBox(height: 16),
              if ((item.inputs['brand'] ?? '') != '')
                Text('Merek: ${item.inputs['brand']}'),
              if ((item.inputs['product_url'] ?? '') != '')
                SelectableText('Link: ${item.inputs['product_url']}'),
              if ((item.inputs['material'] ?? '') != '')
                Text(
                  'Bahan: ${item.inputs['material']} · ${item.inputs['weight_kg']} kg',
                ),
              Text('Sumber: ${item.source}'),
              if (item.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(item.notes),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  openForm(reference: item, fromCatalogue: true);
                },
                child: const Text('Gunakan untuk analisis'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Worth to Buy'),
      actions: [
        IconButton(
          tooltip: 'Carbon Footprint',
          icon: const Icon(Icons.eco_outlined),
          onPressed: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CarbonFootprintHomePage(),
              ),
            );
          },
        ),
        if (!widget.api.hasSession)
          PopupMenuButton<bool>(
            tooltip: 'Pratinjau tampilan',
            onSelected: (analyzer) => setState(() {
              previewAnalyzer = analyzer;
              tab = 0;
              page = 1;
              category = '';
              status = '';
              query = '';
              search.clear();
              future = fetch();
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: false, child: Text('Tampilan User')),
              PopupMenuItem(value: true, child: Text('Tampilan Analyzer')),
            ],
          ),
      ],
    ),
    bottomNavigationBar: tabs.length < 2
        ? null
        : NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: busy
                ? null
                : (index) {
                    setState(() {
                      tab = index;
                      page = 1;
                      query = '';
                      category = '';
                      status = '';
                      search.clear();
                      future = fetch();
                    });
                  },
            destinations: tabs
                .map(
                  (label) => NavigationDestination(
                    icon: Icon(
                      label == 'Riwayat'
                          ? Icons.history
                          : label == 'Katalog'
                          ? Icons.checkroom
                          : Icons.inventory_2_outlined,
                    ),
                    label: label,
                  ),
                )
                .toList(),
          ),
    floatingActionButton: history || workspace
        ? FloatingActionButton.extended(
            onPressed: busy ? null : () => openForm(),
            icon: const Icon(Icons.add),
            label: Text(workspace ? 'Referensi baru' : 'Analisis baru'),
          )
        : null,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.api.hasSession
                          ? 'Halo, ${widget.api.user!.username}'
                          : 'Worth to buy analyzer',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (!widget.api.hasSession) ...[
                      const Text(
                        'Data server dan penyimpanan menunggu integrasi login bersama.',
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      workspace
                          ? 'Referensi pakaian'
                          : history
                          ? 'Belanja dengan pertimbangan.'
                          : 'Temukan referensi pilihan.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      workspace
                          ? 'Kelola draft dan terbitkan referensi ke katalog.'
                          : history
                          ? 'Lihat kembali biaya per pakai dan keputusanmu.'
                          : 'Gunakan referensi untuk memulai analisis pribadi.',
                    ),
                    if (!history) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: search,
                        decoration: InputDecoration(
                          labelText: 'Cari pakaian, merek, atau sumber',
                          suffixIcon: IconButton(
                            tooltip: 'Cari',
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              query = search.text.trim();
                              reload(reset: true);
                            },
                          ),
                        ),
                        onSubmitted: (value) {
                          query = value.trim();
                          reload(reset: true);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<ResultPage<dynamic>>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: RetryMessage(
                          error: snapshot.error!,
                          onRetry: () => reload(),
                        ),
                      );
                    }
                    if (snapshot.connectionState != ConnectionState.done ||
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final result = snapshot.data!;
                    return RefreshIndicator(
                      onRefresh: () async {
                        reload();
                        try {
                          await future;
                        } on ApiException {
                          // The list's FutureBuilder displays the retry state.
                        }
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                        children: [
                          if (!history) ...[
                            DropdownButtonFormField<String>(
                              key: ValueKey('category-$tab-$category'),
                              initialValue: category,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Kategori',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('Semua kategori'),
                                ),
                                ...options!['categories'].map(
                                  (option) => DropdownMenuItem(
                                    value: option.value,
                                    child: Text(option.label),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                category = value ?? '';
                                reload(reset: true);
                              },
                            ),
                            if (workspace)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final entry in {
                                      '': 'Semua',
                                      'draft': 'Draft',
                                      'published': 'Terbit',
                                    }.entries)
                                      ChoiceChip(
                                        label: Text(entry.value),
                                        selected: status == entry.key,
                                        onSelected: (_) {
                                          status = entry.key;
                                          reload(reset: true);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            '${result.count} ${history ? 'analisis' : 'referensi'}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 12),
                          if (result.items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.checkroom_outlined,
                                    size: 56,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    !widget.api.hasSession
                                        ? 'Data server belum dimuat.'
                                        : history
                                        ? 'Belum ada analisis.'
                                        : 'Belum ada referensi yang cocok.',
                                  ),
                                  if (history)
                                    const Text(
                                      'Mulai dari pakaian yang sedang kamu incar.',
                                    ),
                                ],
                              ),
                            ),
                          for (final item in result.items)
                            if (item is PurchaseAnalysis)
                              Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(item.name),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${item.category}\n${rupiah(item.result.costPerWear)} / pakai\n${item.decisionLabel}',
                                    ),
                                  ),
                                  trailing: Text(
                                    '${item.result.score}/100',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  onTap: () async {
                                    await Navigator.push<void>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AnalysisDetailScreen(
                                          api: widget.api,
                                          initial: item,
                                        ),
                                      ),
                                    );
                                    if (mounted) reload();
                                  },
                                ),
                              )
                            else if (item is ClothingReference)
                              Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(item.name),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${item.category} · ${rupiah(item.price)}\n${item.source}${workspace ? '\n${item.published ? 'Terbit' : 'Draft'}' : ''}',
                                    ),
                                  ),
                                  onTap: () => workspace
                                      ? openForm(reference: item)
                                      : openReference(item),
                                  trailing: workspace
                                      ? PopupMenuButton<String>(
                                          enabled: !busy,
                                          onSelected: (action) =>
                                              referenceAction(item, action),
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit'),
                                            ),
                                            PopupMenuItem(
                                              value: 'publication',
                                              child: Text(
                                                item.published
                                                    ? 'Tarik dari katalog'
                                                    : 'Terbitkan',
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Hapus'),
                                            ),
                                          ],
                                        )
                                      : const Icon(Icons.arrow_forward),
                                ),
                              ),
                          if (result.count > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  tooltip: 'Halaman sebelumnya',
                                  onPressed: page > 1
                                      ? () {
                                          page--;
                                          reload();
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text('Halaman $page'),
                                IconButton(
                                  tooltip: 'Halaman berikutnya',
                                  onPressed: result.hasNext
                                      ? () {
                                          page++;
                                          reload();
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
