import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SalarySlipPDFViewer extends StatefulWidget {
  final int salarySlipId;
  final String employeeName;
  final String period;

  const SalarySlipPDFViewer({
    Key? key,
    required this.salarySlipId,
    required this.employeeName,
    required this.period,
  }) : super(key: key);

  @override
  State<SalarySlipPDFViewer> createState() => _SalarySlipPDFViewerState();
}

class _SalarySlipPDFViewerState extends State<SalarySlipPDFViewer> {
  String? localPath;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  int currentPage = 0;
  int totalPages = 0;
  PDFViewController? pdfController;

  @override
  void initState() {
    super.initState();
    loadPDF();
  }

  // Get token dari SharedPreferences (sama seperti pattern yang sudah ada)
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> loadPDF() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final apiUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/api';
      final url = '$apiUrl/salary-slips/${widget.salarySlipId}/pdf';

      print('Loading PDF from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/pdf',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/salary_slip_${widget.salarySlipId}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading PDF: $e');
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> downloadPDF() async {
    try {
      // Check and request storage permission for Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            _showSnackBar(
              'Storage permission is required to download PDF',
              Colors.red,
            );
            return;
          }
        }
      }

      setState(() => isLoading = true);

      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final apiUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/api';
      final url = '$apiUrl/salary-slips/${widget.salarySlipId}/pdf';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode == 200) {
        // Get downloads directory
        Directory? downloadsDir;
        if (Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            downloadsDir = await getExternalStorageDirectory();
          }
        } else {
          downloadsDir = await getApplicationDocumentsDirectory();
        }

        final fileName =
            'salary_slip_${widget.employeeName}_${widget.period}.pdf'
                .replaceAll(' ', '_')
                .replaceAll('/', '-');

        final file = File('${downloadsDir!.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        setState(() => isLoading = false);

        _showSnackBar('PDF downloaded successfully!', Colors.green);
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Download failed: ${e.toString()}', Colors.red);
    }
  }

  Future<void> sharePDF() async {
    if (localPath != null) {
      try {
        await Share.shareXFiles([
          XFile(localPath!),
        ], text: 'Salary Slip - ${widget.employeeName} (${widget.period})');
      } catch (e) {
        _showSnackBar('Failed to share PDF: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Salary Slip'),
        subtitle: Text('${widget.employeeName} - ${widget.period}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!isLoading && localPath != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: sharePDF,
              tooltip: 'Share PDF',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: downloadPDF,
              tooltip: 'Download PDF',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    loadPDF();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading PDF...'),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading PDF',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: loadPDF, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (localPath == null) {
      return const Center(child: Text('No PDF available'));
    }

    return PDFView(
      filePath: localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: true,
      pageSnap: true,
      defaultPage: currentPage,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          totalPages = pages ?? 0;
        });
      },
      onError: (error) {
        setState(() {
          hasError = true;
          errorMessage = error.toString();
        });
      },
      onPageError: (page, error) {
        _showSnackBar('Error on page $page: $error', Colors.red);
      },
      onViewCreated: (PDFViewController controller) {
        pdfController = controller;
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          currentPage = page ?? 0;
          totalPages = total ?? 0;
        });
      },
    );
  }

  Widget _buildBottomBar() {
    if (isLoading || hasError || localPath == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 0
                    ? () async {
                        await pdfController?.setPage(currentPage - 1);
                      }
                    : null,
                icon: const Icon(Icons.navigate_before),
              ),
              Text(
                '${currentPage + 1} / $totalPages',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
                onPressed: currentPage < totalPages - 1
                    ? () async {
                        await pdfController?.setPage(currentPage + 1);
                      }
                    : null,
                icon: const Icon(Icons.navigate_next),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton.icon(
              onPressed: downloadPDF,
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Download',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
