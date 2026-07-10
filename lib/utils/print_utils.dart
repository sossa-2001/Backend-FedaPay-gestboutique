import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

Future<void> printInvoice(Order order, String companyName) async {
  final currencyFmt = NumberFormat.currency(
    locale: 'fr',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  final dateFmt = DateFormat('dd/MM/yyyy');
  final timeFmt = DateFormat('HH:mm');
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Facture',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    order.orderNumber,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${dateFmt.format(order.createdAt ?? DateTime.now())} ${timeFmt.format(order.createdAt ?? DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        if (order.customerName != null && order.customerName!.isNotEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Client',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  order.customerName!,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
          headerAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          headers: ['Article', 'Qté', 'P.U.', 'Total'],
          data: order.items
              .map(
                (item) => [
                  item.productName,
                  item.quantity.toStringAsFixed(0),
                  currencyFmt.format(item.unitPrice),
                  currencyFmt.format(item.totalPrice),
                ],
              )
              .toList(),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'Total articles: ${order.items.fold(0.0, (s, i) => s + i.quantity).toStringAsFixed(0)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        'Sous-total',
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        currencyFmt.format(order.subtotal),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                if (order.tax > 0)
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text('Taxe', textAlign: pw.TextAlign.right),
                      ),
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          currencyFmt.format(order.tax),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                if (order.discount > 0)
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text('Remise', textAlign: pw.TextAlign.right),
                      ),
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          currencyFmt.format(order.discount),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                pw.Divider(),
                pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        'Total',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        currencyFmt.format(order.total),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Text(
          'Merci de votre confiance !',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => doc.save(),
  );
}

Future<void> printDeliveryNote(Order order, String companyName) async {
  final dateFmt = DateFormat('dd/MM/yyyy');
  final timeFmt = DateFormat('HH:mm');
  final doc = pw.Document();
  final totalItems = order.items.fold(0.0, (s, i) => s + i.quantity);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Bon de livraison',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    order.orderNumber,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${dateFmt.format(order.createdAt ?? DateTime.now())} ${timeFmt.format(order.createdAt ?? DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        if (order.customerName != null && order.customerName!.isNotEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Livré à',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  order.customerName!,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
          headerAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
          columnWidths: {
            0: const pw.FlexColumnWidth(6),
            1: const pw.FlexColumnWidth(2),
          },
          headers: ['Article', 'Qté'],
          data: order.items
              .map(
                (item) => [item.productName, item.quantity.toStringAsFixed(0)],
              )
              .toList(),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 100,
                      child: pw.Text(
                        "Nombre total d'articles",
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.SizedBox(
                      width: 50,
                      child: pw.Text(
                        totalItems.toStringAsFixed(0),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Text(
          'Merci de votre confiance !',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => doc.save(),
  );
}
