import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../../core/theme/theme.dart';

/// PDF Viewer Screen using Syncfusion
class PdfViewerScreen extends StatefulWidget {
  final String materialId;
  final String title;
  final String url;

  const PdfViewerScreen({
    super.key,
    required this.materialId,
    required this.title,
    required this.url,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  late PdfViewerController _pdfViewerController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _isBookmarked = false;
  int _savedPage = 1;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadSavedState();

    // Lock to portrait for better PDF viewing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBookmarked =
          prefs.getBool('pdf_bookmark_${widget.materialId}') ?? false;
      _savedPage = prefs.getInt('pdf_progress_${widget.materialId}') ?? 1;
    });
  }

  Future<void> _saveProgress(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pdf_progress_${widget.materialId}', page);
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final newState = !_isBookmarked;
    await prefs.setBool('pdf_bookmark_${widget.materialId}', newState);
    await prefs.setInt('pdf_bookmark_page_${widget.materialId}', _currentPage);
    setState(() => _isBookmarked = newState);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState ? 'Bookmarked page $_currentPage' : 'Bookmark removed',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sharePdf() async {
    await Share.share(
      '${widget.title}\n\n${widget.url}',
      subject: widget.title,
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    // Reset to portrait only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTextStyles.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Page indicator
          if (_totalPages > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          // Bookmark button
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              color: _isBookmarked ? AppColors.primary : null,
            ),
            onPressed: _toggleBookmark,
            tooltip: 'Bookmark',
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _sharePdf,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.url,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            onDocumentLoaded: (details) {
              setState(() {
                _totalPages = details.document.pages.count;
                _isLoading = false;
              });
              // Jump to saved page if available
              if (_savedPage > 1 && _savedPage <= _totalPages) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  _pdfViewerController.jumpToPage(_savedPage);
                });
              }
            },
            onPageChanged: (details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
              // Save progress
              _saveProgress(details.newPageNumber);
            },
            onDocumentLoadFailed: (details) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load PDF: ${details.description}'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: AppColors.surface,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 700;

              final prevButton = IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () => _pdfViewerController.previousPage()
                    : null,
              );

              final nextButton = IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages
                    ? () => _pdfViewerController.nextPage()
                    : null,
              );

              final pageButton = TextButton(
                onPressed: () => _showPageJumpDialog(),
                child: Text('Page $_currentPage'),
              );

              final zoomIn = IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () => _pdfViewerController.zoomLevel += 0.25,
              );

              final zoomOut = IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () => _pdfViewerController.zoomLevel -= 0.25,
              );

              if (isCompact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [prevButton, pageButton, nextButton],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [zoomOut, zoomIn],
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  prevButton,
                  pageButton,
                  nextButton,
                  const Spacer(),
                  zoomIn,
                  zoomOut,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPageJumpDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Enter page (1-$_totalPages)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _pdfViewerController.jumpToPage(page);
                Navigator.pop(context);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}
