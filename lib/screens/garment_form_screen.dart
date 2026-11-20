import 'package:flutter/material.dart';

import '../models/worth_to_buy.dart';
import '../services/worth_to_buy_api.dart';
import '../widgets/feedback.dart';

class GarmentFormScreen extends StatefulWidget {
  const GarmentFormScreen({
    super.key,
    required this.api,
    this.reference = false,
    this.id,
    this.initial = const {},
  });
  final WorthToBuyApi api;
  final bool reference;
  final int? id;
  final Json initial;
  @override
  State<GarmentFormScreen> createState() => _GarmentFormScreenState();
}

class _GarmentFormScreenState extends State<GarmentFormScreen> {
  final form = GlobalKey<FormState>();
  late Future<FormOptions> options = widget.api.options();
  final controllers = <String, TextEditingController>{};
  late final Json values = Map.of(widget.initial);
  Json errors = {};
  String? error;
  bool busy = false;
  static const labels = {
    'clothing_name': 'Nama pakaian',
    'category': 'Kategori',
    'brand': 'Merek (opsional)',
    'product_url': 'Link produk (opsional)',
    'price': 'Harga (Rp)',
    'budget': 'Budget (Rp)',
    'expected_wears': 'Perkiraan total pemakaian',
    'target_cpw': 'Target biaya per pakai (Rp)',
    'wears_per_month': 'Pemakaian per bulan (opsional)',
    'existing_clothing': 'Sudah punya yang serupa?',
    'purpose': 'Tujuan penggunaan',
    'material': 'Bahan utama (opsional)',
    'weight_kg': 'Berat (kg, opsional)',
    'source_name': 'Sumber referensi',
    'notes': 'Catatan referensi (opsional)',
  };
  static const numeric = {
    'price',
    'budget',
    'expected_wears',
    'target_cpw',
    'wears_per_month',
    'weight_kg',
  };
  static const optional = {
    'brand',
    'product_url',
    'wears_per_month',
    'material',
    'weight_kg',
    'notes',
  };

  @override
  void initState() {
    super.initState();
    for (final name in {...analysisFields, ...referenceFields}) {
      controllers[name] = TextEditingController(
        text: widget.initial[name]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? validate(String name, String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) {
      if (!optional.contains(name)) return 'Wajib diisi.';
      if (name == 'weight_kg' && (values['material'] ?? '') != '') {
        return 'Isi berat bersama bahan utama.';
      }
      return null;
    }
    if (numeric.contains(name)) {
      final amount = double.tryParse(text.replaceAll(',', '.'));
      if (amount == null ||
          !amount.isFinite ||
          (name == 'budget' ? amount < 0 : amount <= 0)) {
        return name == 'budget'
            ? 'Isi angka 0 atau lebih.'
            : 'Isi angka lebih dari 0.';
      }
      if (name == 'expected_wears' && int.tryParse(text) == null) {
        return 'Isi jumlah pemakaian bulat.';
      }
    }
    if (name == 'product_url') {
      final uri = Uri.tryParse(text);
      if (uri == null ||
          !{'http', 'https'}.contains(uri.scheme) ||
          uri.host.isEmpty) {
        return 'Gunakan link http atau https yang valid.';
      }
    }
    return null;
  }

  Widget field(String name) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: ValueKey(name),
      controller: controllers[name],
      enabled: !busy,
      decoration: InputDecoration(
        labelText: labels[name],
        errorText: fieldError(name),
        helperText: {'price', 'budget', 'target_cpw'}.contains(name)
            ? 'Tanpa pemisah ribuan, contoh: 300000'
            : null,
      ),
      keyboardType: numeric.contains(name)
          ? TextInputType.numberWithOptions(decimal: name != 'expected_wears')
          : name == 'product_url'
          ? TextInputType.url
          : TextInputType.text,
      maxLines: name == 'notes' ? 3 : 1,
      validator: (text) => validate(name, text),
    ),
  );

  String? fieldError(String name) {
    final value = errors[name];
    return value is List ? value.join(' ') : value?.toString();
  }

  Widget select(String name, List<Choice> choices) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: DropdownButtonFormField<String>(
      key: ValueKey(name),
      isExpanded: true,
      initialValue: values[name]?.toString() ?? '',
      decoration: InputDecoration(
        labelText: labels[name],
        errorText: fieldError(name),
      ),
      items: [
        DropdownMenuItem(
          value: '',
          child: Text(name == 'material' ? 'Tanpa estimasi karbon' : 'Pilih…'),
        ),
        ...choices.map(
          (choice) => DropdownMenuItem(
            value: choice.value,
            child: Text(choice.label, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: busy
          ? null
          : (value) => setState(() {
              values[name] = value;
            }),
      validator: (value) {
        if (name == 'material') {
          if ((value ?? '').isEmpty &&
              controllers['weight_kg']!.text.trim().isNotEmpty) {
            return 'Pilih bahan bersama berat pakaian.';
          }
          return null;
        }
        return value == null || value.isEmpty ? 'Pilih salah satu.' : null;
      },
    ),
  );

  Future<void> save() async {
    setState(() {
      errors = {};
      error = null;
    });
    if (!form.currentState!.validate()) return;
    final fields = widget.reference ? referenceFields : analysisFields;
    final payload = <String, dynamic>{};
    for (final name in fields) {
      if (name == 'is_published') {
        payload[name] = values[name] ?? false;
        continue;
      }
      if ({
        'category',
        'material',
        'existing_clothing',
        'purpose',
      }.contains(name)) {
        payload[name] = values[name] ?? '';
        continue;
      }
      final text = controllers[name]!.text.trim();
      payload[name] = numeric.contains(name) && text.isEmpty
          ? null
          : numeric.contains(name)
          ? text.replaceAll(',', '.')
          : text;
    }
    setState(() {
      busy = true;
    });
    try {
      final Object result = widget.reference
          ? await widget.api.saveReference(payload, id: widget.id)
          : await widget.api.saveAnalysis(payload, id: widget.id);
      if (mounted) Navigator.pop(context, result);
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          errors = exception.fields;
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

  Widget section(String title) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 20),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.id == null ? 'Tambah' : 'Edit'} ${widget.reference ? 'referensi' : 'analisis'}',
        ),
      ),
      body: FutureBuilder<FormOptions>(
        future: options,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: RetryMessage(
                error: snapshot.error!,
                onRetry: () => setState(() {
                  options = widget.api.options();
                }),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final choices = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: form,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      widget.reference
                          ? 'Bagikan referensi untuk pilihan yang lebih bijak.'
                          : 'Pertimbangkan pakaian baru sebelum membelinya.',
                    ),
                    section('01 / Pakaian incaran'),
                    field('clothing_name'),
                    select('category', choices['categories']),
                    field('brand'),
                    field('product_url'),
                    field('price'),
                    if (!widget.reference) ...[
                      section('02 / Kebutuhan & rencana'),
                      field('budget'),
                      select('existing_clothing', choices['existing_clothing']),
                      select('purpose', choices['purposes']),
                      field('expected_wears'),
                      field('target_cpw'),
                      field('wears_per_month'),
                    ],
                    section('03 / Estimasi karbon'),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Isi bahan dan berat bersama, atau kosongkan keduanya.',
                      ),
                    ),
                    select('material', choices['materials']),
                    field('weight_kg'),
                    if (widget.reference) ...[
                      section('04 / Sumber & publikasi'),
                      field('source_name'),
                      field('notes'),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Terbitkan ke katalog'),
                        subtitle: const Text(
                          'Referensi draft hanya terlihat oleh Analyzer.',
                        ),
                        value: values['is_published'] == true,
                        onChanged: busy
                            ? null
                            : (value) => setState(() {
                                values['is_published'] = value;
                              }),
                      ),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '${error!}${errors['__all__'] == null ? '' : '\n${errors['__all__']}'}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: busy ? null : save,
                      child: Text(
                        busy
                            ? 'Menyimpan…'
                            : widget.reference
                            ? 'Simpan referensi'
                            : 'Simpan & lihat hasil',
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
