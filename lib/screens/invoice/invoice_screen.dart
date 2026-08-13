import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/job_card.dart';
import '../../providers/auth_provider.dart';
import '../../services/job_card_service.dart';
import '../../widgets/rpm_gauge_loader.dart';

class InvoiceScreen extends StatefulWidget {
  final int id;
  const InvoiceScreen({super.key, required this.id});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  JobCard? _jobCard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final jc = await JobCardService.get(widget.id);
      setState(() { _jobCard = jc; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  void _shareWhatsApp(String garageName) async {
    if (_jobCard == null) return;
    final jc = _jobCard!;
    final itemLines = jc.items.map((i) => '  • ${i.description}: ₹${i.price.toStringAsFixed(0)}').join('\n');
    final message = '''
*$garageName* 🔧
━━━━━━━━━━━━━━━━━
*Bill for: ${jc.customer?.name ?? ''}*
📱 ${jc.customer?.phone ?? ''}
🏍️ ${jc.vehicle?.vehicleNumber ?? ''} ${jc.vehicle?.brand != null ? '(${jc.vehicle!.brand})' : ''}
📅 ${_formatDate(jc.completedAt ?? jc.createdAt)}

*Items:*
$itemLines
━━━━━━━━━━━━━━━━━
💰 *Total: ₹${jc.finalTotal.toStringAsFixed(2)}*

Thank you for visiting $garageName! 🙏
''';

    await Share.share(message, subject: 'Bill from $garageName');
  }

  Future<void> _savePdf(String garageName) async {
    if (_jobCard == null) return;
    final jc = _jobCard!;

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(child: pw.Text(garageName.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.Center(child: pw.Text('Two-Wheeler Repair & Service', style: const pw.TextStyle(fontSize: 12))),
          pw.SizedBox(height: 4),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.Text('Name   : ${jc.customer?.name ?? ''}'),
          pw.Text('Phone  : ${jc.customer?.phone ?? ''}'),
          pw.Text('Vehicle: ${jc.vehicle?.vehicleNumber ?? ''} ${jc.vehicle?.brand != null ? '(${jc.vehicle!.brand} ${jc.vehicle!.model ?? ''})' : ''}'),
          pw.Text('Date   : ${_formatDate(jc.completedAt ?? jc.createdAt)}'),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('Items:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: ['Description', 'Type', 'Price (₹)']
                    .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))))
                    .toList(),
              ),
              ...jc.items.map((i) => pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(i.description, style: const pw.TextStyle(fontSize: 11))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(i.type, style: const pw.TextStyle(fontSize: 11))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(i.price.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 11))),
                ],
              )),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Text('TOTAL: ₹${jc.finalTotal.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ]),
          pw.SizedBox(height: 32),
          pw.Center(child: pw.Text('Thank you for your business! 🙏', style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    ));

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'invoice_${jc.id}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final garageName = context.watch<AuthProvider>().garageName ?? 'Garage Management';

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text('Invoice'),
        backgroundColor: AppTheme.kSurface,
      ),
      body: _loading
          ? const Center(
              child: RpmGaugeLoader(
                size: 150.0,
                statusMessages: [
                  'Generating invoice',
                  'Preparing bill details',
                  'Almost ready',
                ],
              ),
            )
          : _jobCard == null
              ? const Center(child: Text('Could not load invoice', style: TextStyle(color: AppTheme.kTextMuted)))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Center(
                                  child: Text(garageName.toUpperCase(),
                                      style: const TextStyle(color: Color(0xFFF97316), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                ),
                                const Center(
                                  child: Text('Two-Wheeler Repair & Service',
                                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Color(0xFFE5E7EB)),

                                // Bill info
                                const SizedBox(height: 12),
                                _infoRow('Customer', _jobCard!.customer?.name ?? ''),
                                _infoRow('Phone', _jobCard!.customer?.phone ?? ''),
                                _infoRow('Vehicle', '${_jobCard!.vehicle?.vehicleNumber ?? ''} ${_jobCard!.vehicle?.brand != null ? '(${_jobCard!.vehicle!.brand})' : ''}'),
                                _infoRow('Date', _formatDate(_jobCard!.completedAt ?? _jobCard!.createdAt)),

                                const SizedBox(height: 16),
                                const Divider(color: Color(0xFFE5E7EB)),
                                const SizedBox(height: 8),

                                // Items
                                const Text('ITEMS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                const SizedBox(height: 8),
                                ..._jobCard!.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(item.description, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                                          Text(item.type[0].toUpperCase() + item.type.substring(1), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ]),
                                      ),
                                      Text('₹${item.price.toStringAsFixed(2)}',
                                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )),

                                const SizedBox(height: 8),
                                const Divider(color: Color(0xFFE5E7EB)),

                                // Total
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('TOTAL', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                                  Text('₹${_jobCard!.finalTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 20)),
                                ]),

                                const SizedBox(height: 16),
                                Center(
                                  child: Text('Thank you for visiting $garageName! 🙏',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Action Buttons
                    Container(
                      color: AppTheme.kSurface,
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14)),
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => _shareWhatsApp(garageName),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.kPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14)),
                            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                            label: const Text('Save PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => _savePdf(garageName),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 72, child: Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
