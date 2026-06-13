import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Minimal Markdown renderer for GitHub release notes. It handles the small
/// subset that shows up in our changelogs — headings (`#`/`##`/`###`), bullet
/// lists (`-`/`*`/`•`), inline `**bold**`, links, and inline `code` — and
/// styles them with the app's own text tokens. It is intentionally not a full
/// CommonMark implementation; unsupported syntax simply renders as plain text.
class SimpleMarkdown extends StatelessWidget {
  final String data;

  /// Base size for body/bullet text. Headings scale up from here.
  final double baseFontSize;

  const SimpleMarkdown({
    super.key,
    required this.data,
    this.baseFontSize = 13.5,
  });

  @override
  Widget build(BuildContext context) {
    final body = AppTextStyles.body.copyWith(fontSize: baseFontSize);
    final blocks = <Widget>[];
    final lines = data.replaceAll('\r\n', '\n').split('\n');

    for (final raw in lines) {
      final line = raw.trim();

      if (line.isEmpty) {
        blocks.add(const SizedBox(height: 8));
        continue;
      }

      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (heading != null) {
        final level = heading.group(1)!.length;
        blocks.add(
          Padding(
            padding: EdgeInsets.only(top: blocks.isEmpty ? 0 : 6, bottom: 4),
            child: RichText(
              text: _inline(
                heading.group(2)!,
                AppTextStyles.bodyStrong.copyWith(
                  fontSize: level <= 1
                      ? baseFontSize + 1.5
                      : baseFontSize + 0.5,
                ),
              ),
            ),
          ),
        );
        continue;
      }

      final bullet = RegExp(r'^[-*•]\s+(.*)$').firstMatch(line);
      if (bullet != null) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 5, left: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 9),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ).copyWith(color: AppColors.inkMid),
                  ),
                ),
                Expanded(
                  child: RichText(text: _inline(bullet.group(1)!, body)),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(text: _inline(line, body)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  /// Parses inline `**bold**` runs into spans. Links (`[text](url)`) are reduced
  /// to their visible text and inline `` `code` `` to its contents beforehand.
  TextSpan _inline(String text, TextStyle base) {
    final flattened = text
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m.group(1)!)
        .replaceAll('`', '');

    final spans = <TextSpan>[];
    final bold = RegExp(r'\*\*(.+?)\*\*');
    var index = 0;
    for (final m in bold.allMatches(flattened)) {
      if (m.start > index) {
        spans.add(TextSpan(text: flattened.substring(index, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      index = m.end;
    }
    if (index < flattened.length) {
      spans.add(TextSpan(text: flattened.substring(index)));
    }

    return TextSpan(style: base, children: spans);
  }
}
