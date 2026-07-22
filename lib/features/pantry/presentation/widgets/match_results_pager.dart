import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/pantry_provider.dart';

/// Hiển thị món khớp theo trang: mỗi trang 5 món, quẹt ngang để xem thêm.
class MatchResultsPager extends StatefulWidget {
  const MatchResultsPager({
    super.key,
    required this.matches,
  });

  final List<MealIngredientMatch> matches;

  static const int pageSize = 5;

  @override
  State<MatchResultsPager> createState() => _MatchResultsPagerState();
}

class _MatchResultsPagerState extends State<MatchResultsPager> {
  late final PageController _controller;
  int _page = 0;

  int get _pageCount =>
      (widget.matches.length / MatchResultsPager.pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didUpdateWidget(covariant MatchResultsPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matches.length != widget.matches.length &&
        _page >= _pageCount) {
      _page = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MealIngredientMatch> _pageItems(int pageIndex) {
    final start = pageIndex * MatchResultsPager.pageSize;
    final end = (start + MatchResultsPager.pageSize)
        .clamp(0, widget.matches.length);
    return widget.matches.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Đủ chỗ cho 5 ô gọn + margin, tránh bottom overflow.
    const pagerHeight = 360.0;

    return Column(
      children: [
        SizedBox(
          height: pagerHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: _pageCount,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, pageIndex) {
              final items = _pageItems(pageIndex);
              return Column(
                children: [
                  for (final match in items)
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: scheme.primaryContainer,
                            child: Text(
                              '${(match.matchRatio * 100).round()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            match.meal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${match.meal.category.label} · '
                            '${match.matchedIngredients.join(', ')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  for (var i = items.length;
                      i < MatchResultsPager.pageSize;
                      i++)
                    const Expanded(child: SizedBox.shrink()),
                ],
              );
            },
          ),
        ),
        if (_pageCount > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pageCount, (index) {
              final active = index == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? scheme.primary
                      : scheme.outlineVariant.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
