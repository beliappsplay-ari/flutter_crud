import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../services/timesheet_service.dart';

class TimesheetPdfViewer extends StatefulWidget {
  final String period;
  final String employeeName;
  final String pdfUrl;
  final String? empno;

  const TimesheetPdfViewer({
    Key? key,
    required this.period,
    required this.employeeName,
    required this.pdfUrl,
    this.empno,
  }) : super(key: key);

  @override
  State<TimesheetPdfViewer> createState() => _TimesheetPdfViewerState();
}

class _TimesheetPdfViewerState extends State<TimesheetPdfViewer> {
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
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      final token = await TimesheetService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('📋 [TimesheetPdfViewer] Loading PDF from: ${widget.pdfUrl}');

      final response = await http
          .get(
            Uri.parse(widget.pdfUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/pdf',
              'Content-Type': 'application/pdf',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📋 [TimesheetPdfViewer] Response status: ${response.statusCode}');
      print(
        '📋 [TimesheetPdfViewer] Response length: ${response.bodyBytes.length}',
      );

      if (response.statusCode == 200) {
        // ✅ Verify PDF content
        if (response.bodyBytes.length < 100) {
          throw Exception('Invalid PDF content - file too small');
        }

        // ✅ Check PDF header
        final header = String.fromCharCodes(response.bodyBytes.take(4));
        if (!header.startsWith('%PDF')) {
          throw Exception('Invalid PDF format - header: $header');
        }

        // Save to cache directory
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/timesheet_${widget.period}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        print('✅ [TimesheetPdfViewer] PDF saved to: ${file.path}');

        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('❌ [TimesheetPdfViewer] Error: $e');
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  /// ✅ IMPROVED: Simple download without complex permissions
  Future<void> _downloadPDF() async {
    try {
      print('🔽 Starting timesheet PDF download...');

      _showSnackBar('Downloading PDF...', Colors.orange);

      // ✅ Use existing local PDF if available
      if (localPath != null && await File(localPath!).exists()) {
        await _saveToDownloads(localPath!);
        return;
      }

      // ✅ Download fresh PDF
      final token = await TimesheetService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse(widget.pdfUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_download.pdf');
        await tempFile.writeAsBytes(response.bodyBytes);

        await _saveToDownloads(tempFile.path);
        await tempFile.delete(); // Clean up temp file
      } else {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Download error: $e');
      _showSnackBar('Download failed: ${e.toString()}', Colors.red);
    }
  }

  /// ✅ Save PDF to app-specific external storage (no permissions needed)
  Future<void> _saveToDownloads(String sourcePath) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String fileName =
          'timesheet_${widget.employeeName}_${_formatPeriod(widget.period)}_$timestamp.pdf'
              .replaceAll(' ', '_')
              .replaceAll('/', '-')
              .replaceAll(':', '')
              .replaceAll('\\', '');

      Directory? saveDir;
      String downloadPath;

      if (Platform.isAndroid) {
        // ✅ Use app-specific external storage (Android/data/package/files)
        saveDir = await getExternalStorageDirectory();
        if (saveDir == null) {
          throw Exception('Cannot access external storage');
        }
        downloadPath = '${saveDir.path}/Downloads';
        await Directory(downloadPath).create(recursive: true);
      } else {
        // iOS: Use documents directory
        saveDir = await getApplicationDocumentsDirectory();
        downloadPath = saveDir.path;
      }

      final sourceFile = File(sourcePath);
      final targetFile = File('$downloadPath/$fileName');

      await sourceFile.copy(targetFile.path);

      print('✅ PDF saved to: ${targetFile.path}');
      print('📊 File size: ${await targetFile.length()} bytes');

      _showSnackBar(
        'PDF downloaded successfully!\nSaved to: ${Platform.isAndroid ? 'Android/data/.../Downloads/' : 'Documents/'}$fileName',
        Colors.green,
      );
    } catch (e) {
      throw Exception('Save failed: $e');
    }
  }

  Future<void> _sharePDF() async {
    if (localPath != null) {
      try {
        await Share.shareXFiles(
          [XFile(localPath!)],
          text:
              'Timesheet - ${widget.employeeName} (${_formatPeriod(widget.period)})',
        );
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
        duration: Duration(seconds: color == Colors.green ? 4 : 3),
      ),
    );
  }

  String _formatPeriod(String period) {
    if (period.length == 6) {
      final year = period.substring(0, 4);
      final month = period.substring(4, 6);

      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final monthIndex = int.tryParse(month);
      if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
        return '${months[monthIndex - 1]} $year';
      }
    }
    return period;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timesheet - ${widget.employeeName}'),
            if (widget.empno != null && widget.empno!.isNotEmpty)
              Text(
                'Employee: ${widget.empno}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          if (!isLoading && localPath != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePDF,
              tooltip: 'Share PDF',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadPDF,
              tooltip: 'Download PDF',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    _loadPDF();
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
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            SizedBox(height: 16),
            Text('Loading timesheet PDF...'),
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
              'Error loading timesheet PDF',
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
            ElevatedButton(
              onPressed: _loadPDF,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (localPath == null) {
      return const Center(child: Text('No timesheet PDF available'));
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
        print('Timesheet PDF rendered with $totalPages pages');
      },
      onError: (error) {
        print('Timesheet PDF Error: $error');
        setState(() {
          hasError = true;
          errorMessage = error.toString();
        });
      },
      onPageError: (page, error) {
        print('Timesheet PDF Page Error - Page $page: $error');
        _showSnackBar('Error on page $page: $error', Colors.red);
      },
      onViewCreated: (PDFViewController controller) {
        pdfController = controller;
        print('Timesheet PDF View Controller created');
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          currentPage = page ?? 0;
          totalPages = total ?? 0;
        });
        print('Timesheet page changed to: ${currentPage + 1}/$totalPages');
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Page Navigation
          IconButton(
            onPressed: currentPage > 0
                ? () async {
                    await pdfController?.setPage(currentPage - 1);
                  }
                : null,
            icon: const Icon(Icons.navigate_before),
            tooltip: 'Previous Page',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${currentPage + 1} / $totalPages',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: currentPage < totalPages - 1
                ? () async {
                    await pdfController?.setPage(currentPage + 1);
                  }
                : null,
            icon: const Icon(Icons.navigate_next),
            tooltip: 'Next Page',
          ),
        ],
      ),
    );
  }
}
