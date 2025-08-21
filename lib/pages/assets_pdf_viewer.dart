import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/assets_pdf_service.dart';
import 'dart:io';

class AssetsPdfViewer extends StatefulWidget {
  final String empno;
  final String period;
  final String employeeName;

  const AssetsPdfViewer({
    Key? key,
    required this.empno,
    required this.period,
    required this.employeeName,
  }) : super(key: key);

  @override
  State<AssetsPdfViewer> createState() => _AssetsPdfViewerState();
}

class _AssetsPdfViewerState extends State<AssetsPdfViewer> {
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

  Future<void> loadPDF() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      print('Loading PDF from assets for: ${widget.empno} - ${widget.period}');

      final pdfBytes = await AssetsPdfService.downloadPdfBytes(
        widget.empno,
        widget.period,
      );

      if (pdfBytes == null) {
        throw Exception('Failed to download PDF from server');
      }

      final dir = await getTemporaryDirectory();
      final fileName = '${widget.empno}-${widget.period}-assets.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      print('Assets PDF saved to: ${file.path}');

      setState(() {
        localPath = file.path;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading assets PDF: $e');
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  // Enhanced permission request method
  Future<bool> _requestStoragePermission() async {
    if (Platform.isIOS) {
      // iOS doesn't need storage permission for saving to app directory
      return true;
    }

    try {
      // Get Android SDK version
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      print('Android SDK: $sdkInt');

      // For Android 13+ (API 33+)
      if (sdkInt >= 33) {
        // Android 13+ uses scoped storage, download langsung ke Downloads tanpa permission
        return true;
      }
      // For Android 11-12 (API 30-32)
      else if (sdkInt >= 30) {
        // Try MANAGE_EXTERNAL_STORAGE first
        var manageStorageStatus = await Permission.manageExternalStorage.status;

        if (!manageStorageStatus.isGranted) {
          // Show explanation dialog first
          bool shouldRequest = await _showPermissionDialog(
            title: 'Storage Access Required',
            content:
                'This app needs access to device storage to download PDF files to your Downloads folder.\n\nPlease grant "All files access" in the next screen.',
            actionText: 'Grant Access',
          );

          if (!shouldRequest) return false;

          // Request MANAGE_EXTERNAL_STORAGE
          manageStorageStatus = await Permission.manageExternalStorage
              .request();

          if (manageStorageStatus.isGranted) {
            return true;
          } else if (manageStorageStatus.isPermanentlyDenied) {
            await _showSettingsDialog();
            return false;
          }
        } else {
          return true;
        }

        // Fallback to storage permission
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        return storageStatus.isGranted;
      }
      // For Android 10 and below (API 29-)
      else {
        var storageStatus = await Permission.storage.status;

        if (!storageStatus.isGranted) {
          // Show explanation dialog first
          bool shouldRequest = await _showPermissionDialog(
            title: 'Storage Permission Required',
            content:
                'This app needs storage permission to download PDF files to your device.',
            actionText: 'Grant Permission',
          );

          if (!shouldRequest) return false;

          storageStatus = await Permission.storage.request();

          if (storageStatus.isPermanentlyDenied) {
            await _showSettingsDialog();
            return false;
          }
        }

        return storageStatus.isGranted;
      }
    } catch (e) {
      print('Error requesting storage permission: $e');
      _showSnackBar('Permission error: $e', Colors.red);
      return false;
    }
  }

  Future<bool> _showPermissionDialog({
    required String title,
    required String content,
    required String actionText,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.folder_open, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(child: Text(title)),
                ],
              ),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(actionText),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _showSettingsDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.settings, color: Colors.orange),
              SizedBox(width: 8),
              Text('Permission Required'),
            ],
          ),
          content: Text(
            'Storage permission is required to download files. '
            'Please enable it in app settings.\n\n'
            'Settings → Apps → HRIS DGE → Permissions → Storage',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> downloadPDF() async {
    try {
      // Show loading indicator
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
              Text('Preparing download...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      // Request storage permission
      bool hasPermission = await _requestStoragePermission();

      if (!hasPermission) {
        _showSnackBar('Storage permission denied', Colors.red);
        return;
      }

      // Show downloading indicator
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
              Text('Downloading server PDF...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final pdfBytes = await AssetsPdfService.downloadPdfBytes(
        widget.empno,
        widget.period,
      );

      if (pdfBytes == null) {
        throw Exception('Failed to download PDF from server');
      }

      String? finalPath;

      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          // Android 13+ - Use Downloads directory directly
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            finalPath = downloadsDir.path;
          } else {
            // Fallback to app external directory
            final saveDir = await getExternalStorageDirectory();
            if (saveDir != null) {
              finalPath = '${saveDir.path}/Download';
              await Directory(finalPath).create(recursive: true);
            }
          }
        } else {
          // Android 12 and below - Use traditional approach
          List<String> downloadPaths = [
            '/storage/emulated/0/Download',
            '/storage/emulated/0/Downloads',
          ];

          for (String path in downloadPaths) {
            Directory testDir = Directory(path);
            if (await testDir.exists()) {
              try {
                final testFile = File('$path/test_write.tmp');
                await testFile.writeAsString('test');
                await testFile.delete();
                finalPath = path;
                break;
              } catch (e) {
                continue;
              }
            }
          }

          if (finalPath == null) {
            final saveDir = await getExternalStorageDirectory();
            if (saveDir != null) {
              finalPath = '${saveDir.path}/Download';
              await Directory(finalPath).create(recursive: true);
            }
          }
        }
      } else {
        // iOS
        final saveDir = await getApplicationDocumentsDirectory();
        finalPath = saveDir.path;
      }

      if (finalPath == null) {
        throw Exception('Could not access storage directory');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'salary_slip_${widget.empno}_${widget.period}_$timestamp.pdf';
      final file = File('$finalPath/$fileName');
      await file.writeAsBytes(pdfBytes);

      String displayPath = finalPath.contains('/Android/data/')
          ? 'App folder: $fileName'
          : 'Downloads folder: $fileName';

      _showSnackBar('✅ Server PDF downloaded!\n$displayPath', Colors.green);

      // Show success dialog with option to open file location
      _showDownloadSuccessDialog(fileName, finalPath);
    } catch (e) {
      print('Download error: $e');
      _showSnackBar('Download failed: ${e.toString()}', Colors.red);
    }
  }

  void _showDownloadSuccessDialog(String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Download Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File saved successfully:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  fileName,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Location: ${filePath.contains('/Android/data/') ? 'App Downloads folder' : 'Downloads folder'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> sharePDF() async {
    if (localPath != null) {
      try {
        await Share.shareXFiles(
          [XFile(localPath!)],
          text:
              'Server Salary Slip - ${widget.employeeName} (${widget.period})',
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
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SALARY SLIP PDF - ${widget.employeeName}'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
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
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadPDF,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Loading server PDF...'),
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
              'Error loading server PDF',
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
      return const Center(child: Text('No server PDF available'));
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
      onRender: (pages) => setState(() => totalPages = pages ?? 0),
      onError: (error) => setState(() {
        hasError = true;
        errorMessage = error.toString();
      }),
      onViewCreated: (PDFViewController controller) =>
          pdfController = controller,
      onPageChanged: (int? page, int? total) => setState(() {
        currentPage = page ?? 0;
        totalPages = total ?? 0;
      }),
    );
  }
}
