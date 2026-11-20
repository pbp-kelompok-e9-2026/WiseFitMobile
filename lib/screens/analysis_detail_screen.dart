import 'package:flutter/material.dart';

import '../models/worth_to_buy.dart';
import '../services/worth_to_buy_api.dart';
import '../widgets/feedback.dart';
import 'garment_form_screen.dart';

class AnalysisDetailScreen extends StatefulWidget {
  const AnalysisDetailScreen({
    super.key,
    required this.api,
    required this.initial,
  });
  final WorthToBuyApi api;
  final PurchaseAnalysis initial;
  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  late PurchaseAnalysis item = widget.initial;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    if (item.notice.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showMessage(context, item.notice);
      });
    }
  }

  Future<void> edit() async {
    final saved = await Navigator.push<PurchaseAnalysis>(
      context,
      MaterialPageRoute(
        builder: (_) => GarmentFormScreen(
          api: widget.api,
          id: item.id,
          initial: item.inputs,
        ),
      ),
    );
    if (mounted && saved != null) {
      setState(() {
        item = saved;
      });
      if (saved.notice.isNotEmpty) showMessage(context, saved.notice);
    }
  }

  Future<void> remove() async {
    if (!await confirmDelete(context, item.name) || !mounted) return;
    setState(() {
      busy = true;
    });
    try {
      await widget.api.deleteAnalysis(item.id);
      if (mounted) Navigator.pop(context);
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

  Future<void> refreshCarbon() async {
    setState(() {
      busy = true;
    });
    try {
      final saved = await widget.api.refreshCarbon(item.id);
      if (mounted) {
        setState(() {
          item = saved;
        });
        showMessage(
          context,
          saved.notice.isNotEmpty
              ? saved.notice
              : saved.carbon == null
              ? 'Lengkapi bahan dan berat melalui Edit analisis.'
              : 'Estimasi karbon diperbarui.',
        );
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

  Future<void> decision() async {
    final saved = await Navigator.push<PurchaseAnalysis>(
      context,
      MaterialPageRoute(
        builder: (_) => DecisionScreen(api: widget.api, item: item),
      ),
    );
    if (mounted && saved != null) {
      setState(() {
        item = saved;
      });
    }
  }

  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Flexible(child: Text(value, textAlign: TextAlign.right)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final result = item.result;
    const breakdownLabels = {
      'cost_per_wear': 'Biaya per pakai',
      'budget': 'Budget',
      'existing_clothing': 'Pakaian yang dimiliki',
      'purpose': 'Tujuan pemakaian',
    };
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hasil analisis'),
          actions: [
            IconButton(
              tooltip: 'Edit analisis',
              onPressed: busy ? null : edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Hapus analisis',
              onPressed: busy ? null : remove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  item.category.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xffdce2d0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${result.score}/100',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const Text('Purchase score'),
                      const SizedBox(height: 20),
                      Text(
                        result.recommendation,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(result.reason),
                    ],
                  ),
                ),
                heading('Rencana pemakaian'),
                line('Harga', rupiah(item.inputs['price'])),
                line('Budget', rupiah(item.inputs['budget'])),
                line('Biaya per pakai', rupiah(result.costPerWear)),
                line(
                  'Target biaya per pakai',
                  rupiah(item.inputs['target_cpw']),
                ),
                line(
                  'Rencana total pemakaian',
                  '${item.inputs['expected_wears']} kali',
                ),
                line(
                  'Pemakaian untuk mencapai target',
                  '${result.wearsToTarget} kali',
                ),
                if (result.monthsToTarget != null)
                  line(
                    'Perkiraan mencapai target',
                    '${result.monthsToTarget} bulan',
                  ),
                line('Sesuai budget', result.withinBudget ? 'Ya' : 'Belum'),
                line(
                  'Sesuai target biaya',
                  result.meetsTarget ? 'Ya' : 'Belum',
                ),
                if ((item.inputs['brand'] ?? '') != '')
                  line('Merek', item.inputs['brand'].toString()),
                if ((item.inputs['product_url'] ?? '') != '')
                  SelectableText('Link produk: ${item.inputs['product_url']}'),
                heading('Rincian skor'),
                ...result.breakdown.entries.map(
                  (entry) => line(
                    breakdownLabels[entry.key] ?? entry.key,
                    entry.value,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Skor ini adalah panduan pertimbangan pembelian, bukan penilaian ilmiah keberlanjutan.',
                ),
                heading('Estimasi karbon'),
                if (item.carbon == null)
                  const Text(
                    'Estimasi belum tersedia. Isi bahan dan berat untuk menyertakannya.',
                  )
                else ...[
                  line('Estimasi produksi', '${item.carbon} kg CO₂e'),
                  line('Per pemakaian', '${result.carbonPerWear} kg CO₂e'),
                  const SizedBox(height: 8),
                  Text(item.carbonReference),
                  const SizedBox(height: 8),
                  Text(item.carbonScope),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : refreshCarbon,
                  icon: const Icon(Icons.refresh),
                  label: Text(busy ? 'Memproses…' : 'Perbarui estimasi karbon'),
                ),
                heading('Keputusan kamu'),
                Text(
                  item.decisionLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (item.decisionNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(item.decisionNote),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : decision,
                  child: const Text('Simpan keputusan'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DecisionScreen extends StatefulWidget {
  const DecisionScreen({super.key, required this.api, required this.item});
  final WorthToBuyApi api;
  final PurchaseAnalysis item;
  @override
  State<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends State<DecisionScreen> {
  late String decision = widget.item.decision;
  late final note = TextEditingController(text: widget.item.decisionNote);
  late Future<FormOptions> future = widget.api.options();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final item = await widget.api.decide(
        widget.item.id,
        decision,
        note.text.trim(),
      );
      if (mounted) Navigator.pop(context, item);
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Keputusan pembelian')),
      body: FutureBuilder<FormOptions>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: RetryMessage(
                error: snapshot.error!,
                onRetry: () => setState(() {
                  future = widget.api.options();
                }),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: decision,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Keputusan'),
                    items: snapshot.data!['decisions']
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(
                              option.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: busy
                        ? null
                        : (value) => setState(() {
                            decision = value!;
                          }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: note,
                    enabled: !busy,
                    maxLength: 1000,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                    ),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy ? null : save,
                    child: Text(busy ? 'Menyimpan…' : 'Simpan keputusan'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
