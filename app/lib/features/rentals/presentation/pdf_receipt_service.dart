import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/rental.dart';

/// Servicio para generar, imprimir y compartir comprobantes de pago en PDF (HU-36).
class PdfReceiptService {
  /// Genera los bytes del documento PDF del comprobante de pago.
  static Future<Uint8List> generateReceiptPdf(Rental rental) async {
    final pdf = pw.Document();

    final payment = rental.payment;
    final reference = payment?.reference ?? 'N/A';
    final dateStr = payment != null
        ? '${payment.paidAt.day}/${payment.paidAt.month}/${payment.paidAt.year} ${payment.paidAt.hour.toString().padLeft(2, '0')}:${payment.paidAt.minute.toString().padLeft(2, '0')}'
        : 'N/A';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'SRUU - UTEZ',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text(
                      'COMPROBANTE DE PAGO',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 2, color: PdfColors.blue800),
                pw.SizedBox(height: 20),

                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Folio / Referencia de Pago:',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        reference,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Fecha de Transacción: $dateStr',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Text(
                  'Detalle de la Renta',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue800,
                  ),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                  },
                  headers: ['Concepto / Artículo', 'Monto (MXN)'],
                  data: [
                    [rental.listingTitle, '\$${rental.amount.toStringAsFixed(2)} MXN'],
                  ],
                ),
                pw.SizedBox(height: 15),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Rentador: ${rental.renterName}'),
                        pw.Text('Vendedor: ${rental.ownerName}'),
                        pw.Text('Estado del Pago: COMPLETADO'),
                      ],
                    ),
                    pw.Text(
                      'Total: \$${rental.amount.toStringAsFixed(2)} MXN',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),
                pw.Divider(color: PdfColors.grey400),
                pw.Center(
                  child: pw.Text(
                    'Este documento es un comprobante digital emitido por el Sistema de Renta de Útiles Universitarios (SRUU - UTEZ).',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Muestra la vista previa de impresión o descarga del PDF.
  static Future<void> printOrSaveReceipt(Rental rental) async {
    final pdfBytes = await generateReceiptPdf(rental);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Comprobante_${rental.id}.pdf',
    );
  }

  /// Comparte el archivo PDF del comprobante mediante share_plus.
  static Future<void> shareReceiptPdf(Rental rental) async {
    final pdfBytes = await generateReceiptPdf(rental);
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Comprobante_${rental.id}.pdf');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Comprobante de pago SRUU - ${rental.listingTitle}',
    );
  }
}
