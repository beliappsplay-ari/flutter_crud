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

      print('PDF Load response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/salary_slip_${widget.salarySlipId}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        print('PDF saved to: ${file.path}');

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
      print('Starting PDF download...');

      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Downloading PDF...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // For Android, request multiple permissions
      if (Platform.isAndroid) {
        print('Requesting Android permissions...');

        // Request both storage permissions
        Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.manageExternalStorage,
        ].request();

        print('Permission statuses: $statuses');

        // Check if we have any storage permission
        bool hasStoragePermission =
            statuses[Permission.storage]?.isGranted == true ||
            statuses[Permission.manageExternalStorage]?.isGranted == true;

        if (!hasStoragePermission) {
          // Show dialog to explain and redirect to settings
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Storage Permission Required'),
              content: const Text(
                'This app needs storage permission to download PDF files. Please grant storage permission in app settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          return;
        }
      }

      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final apiUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/api';
      final url = '$apiUrl/salary-slips/${widget.salarySlipId}/pdf';

      print('Downloading PDF from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/pdf',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('Download response status: ${response.statusCode}');
      print('Response content length: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        // For emulator, save to easily accessible location
        Directory? saveDir;
        String? finalPath;

        if (Platform.isAndroid) {
          // Try public Downloads directory first (best for emulator)
          List<String> downloadPaths = [
            '/storage/emulated/0/Download',
            '/storage/emulated/0/Downloads',
          ];

          for (String path in downloadPaths) {
            Directory testDir = Directory(path);
            if (await testDir.exists()) {
              try {
                // Test write access
                final testFile = File('$path/test_write.tmp');
                await testFile.writeAsString('test');
                await testFile.delete();

                finalPath = path;
                print('Using public downloads: $path');
                break;
              } catch (e) {
                print('No write access to $path: $e');
                continue;
              }
            }
          }

          // Fallback to external app directory
          if (finalPath == null) {
            saveDir = await getExternalStorageDirectory();
            if (saveDir != null) {
              finalPath = '${saveDir.path}/Download';
              await Directory(finalPath).create(recursive: true);
              print('Using app external directory: $finalPath');
            }
          }
        } else {
          saveDir = await getApplicationDocumentsDirectory();
          finalPath = saveDir.path;
          print('Using documents directory: $finalPath');
        }

        if (finalPath == null) {
          throw Exception('Could not access storage directory');
        }

        // Create filename with timestamp for uniqueness
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName =
            'salary_slip_${widget.employeeName}_${widget.period}_$timestamp.pdf'
                .replaceAll(' ', '_')
                .replaceAll('/', '-')
                .replaceAll(':', '')
                .replaceAll('\\', '');

        print('Saving as: $fileName');

        final file = File('$finalPath/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        print('PDF saved to: ${file.path}');
        print('File exists: ${await file.exists()}');
        print('File size: ${await file.length()} bytes');

        // Show path information
        String displayPath = finalPath.contains('/Android/data/')
            ? 'App folder: $fileName'
            : 'Downloads folder: $fileName';

        _showSnackBar(
          'PDF downloaded successfully!\n$displayPath',
          Colors.green,
        );
      } else {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Download error: $e');
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
        title: Text('Salary Slip - ${widget.employeeName}'),
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
                  case 'zoom_fit':
                    // PDF viewer will handle zoom
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
                const PopupMenuItem(
                  value: 'zoom_fit',
                  child: Row(
                    children: [
                      Icon(Icons.zoom_out_map),
                      SizedBox(width: 8),
                      Text('Fit to Screen'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomBar(),
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Salary Slips',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: 1, // Salary Slips is selected
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            onTap: (int index) {
              switch (index) {
                case 0:
                  // Navigate back to Dashboard
                  Navigator.of(context).pop();
                  break;
                case 1:
                  // Navigate back to Salary Slips list
                  Navigator.of(context).pop();
                  break;
                case 2:
                  // Settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings page coming soon!')),
                  );
                  break;
                case 3:
                  // Profile
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile page coming soon!')),
                  );
                  break;
              }
            },
          ),
        ],
      ),
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
        print('PDF rendered with $totalPages pages');
      },
      onError: (error) {
        print('PDF Error: $error');
        setState(() {
          hasError = true;
          errorMessage = error.toString();
        });
      },
      onPageError: (page, error) {
        print('PDF Page Error - Page $page: $error');
        _showSnackBar('Error on page $page: $error', Colors.red);
      },
      onViewCreated: (PDFViewController controller) {
        pdfController = controller;
        print('PDF View Controller created');
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          currentPage = page ?? 0;
          totalPages = total ?? 0;
        });
        print('Page changed to: ${currentPage + 1}/$totalPages');
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
          // Page Navigation Only
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
              color: Theme.of(context).primaryColor.withOpacity(0.1),
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
