import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:printing/printing.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Print(),
    );
  }
}

class Print extends StatefulWidget {
  Print({Key key}) : super(key: key);

  @override
  _PrintState createState() => _PrintState();
}

class _PrintState extends State<Print> {
  final GlobalKey<State<StatefulWidget>> shareWidget = GlobalKey();
  final GlobalKey<State<StatefulWidget>> previewContainer = GlobalKey();
  PrintingInfo printingInfo;
  pw.Document doc;

  void _showPrintedToast(bool printed) {
    final ScaffoldState scaffold = Scaffold.of(shareWidget.currentContext);
    if (printed) {
      scaffold.showSnackBar(const SnackBar(
        content: Text('Document printed successfully'),
      ));
    } else {
      scaffold.showSnackBar(const SnackBar(
        content: Text('Document not printed'),
      ));
    }
  }

  Future<void> _printScreen() async {
    final bool result =
        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
      final pw.Document document = pw.Document();

      final PdfImage image = await wrapWidget(
        document.document,
        key: previewContainer,
        pixelRatio: 2.0,
      );

      print('Print Screen ${image.width}x${image.height}...');

      document.addPage(pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Expanded(
                child: pw.Image(image),
              ),
            ); // Center
          })); // Page
      doc = document;
      return document.save();
    });

    _showPrintedToast(result);
  }

  Future<void> _sharePdf() async {
    print('Share ...');
    final pw.Document document = doc;

    // Calculate the widget center for iPad sharing popup position
    final RenderBox referenceBox =
        shareWidget.currentContext.findRenderObject();
    final Offset topLeft =
        referenceBox.localToGlobal(referenceBox.paintBounds.topLeft);
    final Offset bottomRight =
        referenceBox.localToGlobal(referenceBox.paintBounds.bottomRight);
    final Rect bounds = Rect.fromPoints(topLeft, bottomRight);

    await Printing.sharePdf(
        bytes: document.save(), filename: 'Document.pdf', bounds: bounds);
  }

  @override
  void initState() {
    Printing.info().then((PrintingInfo info) {
      setState(() {
        printingInfo = info;
      });
    });
    super.initState();
  }

  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: previewContainer,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                key: const Key('Screenshot'),
                child: const Text('Print Screenshot'),
                onPressed: (printingInfo?.canPrint ?? false) && !kIsWeb
                    ? _printScreen
                    : null,
              ),
              RaisedButton(
                key: shareWidget,
                child: const Text('Share Document'),
                onPressed: printingInfo?.canShare ?? false ? _sharePdf : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
