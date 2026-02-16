import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/theme/theme.dart';

/// Note Viewer Screen for viewing text-based notes
class NoteViewerScreen extends StatefulWidget {
  final String materialId;
  final String title;
  final String content;

  const NoteViewerScreen({
    super.key,
    required this.materialId,
    required this.title,
    required this.content,
  });

  @override
  State<NoteViewerScreen> createState() => _NoteViewerScreenState();
}

class _NoteViewerScreenState extends State<NoteViewerScreen> {
  double _fontSize = 16.0;
  bool _isDarkMode = false;

  void _increaseFontSize() {
    if (_fontSize < 28) {
      setState(() => _fontSize += 2);
    }
  }

  void _decreaseFontSize() {
    if (_fontSize > 12) {
      setState(() => _fontSize -= 2);
    }
  }

  void _toggleDarkMode() {
    setState(() => _isDarkMode = !_isDarkMode);
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareNote() async {
    await Share.share(
      '${widget.title}\n\n${widget.content}',
      subject: widget.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTextStyles.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: isCompact
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'decrease':
                        _decreaseFontSize();
                        break;
                      case 'increase':
                        _increaseFontSize();
                        break;
                      case 'mode':
                        _toggleDarkMode();
                        break;
                      case 'copy':
                        _copyToClipboard();
                        break;
                      case 'share':
                        _shareNote();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'decrease',
                      child: Text('Decrease font'),
                    ),
                    const PopupMenuItem(
                      value: 'increase',
                      child: Text('Increase font'),
                    ),
                    PopupMenuItem(
                      value: 'mode',
                      child: Text(_isDarkMode ? 'Light mode' : 'Dark mode'),
                    ),
                    const PopupMenuItem(value: 'copy', child: Text('Copy')),
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                  ],
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.text_decrease),
                  onPressed: _decreaseFontSize,
                  tooltip: 'Decrease font size',
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase),
                  onPressed: _increaseFontSize,
                  tooltip: 'Increase font size',
                ),
                IconButton(
                  icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: _toggleDarkMode,
                  tooltip: _isDarkMode ? 'Light mode' : 'Dark mode',
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: _copyToClipboard,
                  tooltip: 'Copy',
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: _shareNote,
                  tooltip: 'Share',
                ),
              ],
      ),
      body: Container(
        color: backgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SelectableText(
            widget.content,
            style: TextStyle(
              fontSize: _fontSize,
              color: textColor,
              height: 1.6,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Font size: ${_fontSize.toInt()}',
              style: AppTextStyles.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
