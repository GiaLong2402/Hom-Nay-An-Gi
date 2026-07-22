import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/meal_model.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/primary_app_bar.dart';
import '../../../meals/presentation/providers/meals_provider.dart';
import '../../data/pantry_ingredient_classifier.dart';
import '../../data/pantry_ingredients.dart';
import '../providers/pantry_provider.dart';
import '../widgets/ingredient_picker.dart';
import '../widgets/match_results_pager.dart';

/// Màn hình Tủ lạnh — chọn nguyên liệu, lọc món, gợi ý món mới.
class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  final _aiSectionKey = GlobalKey();

  bool _isAskingAi = false;
  bool _isSyncing = false;
  String? _aiStatus;
  List<MealModel> _aiSuggestions = const [];
  final Set<String> _savedSuggestionKeys = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      setState(() => _isSyncing = true);
      try {
        await syncMealIngredientsFromPreset(ref);
      } catch (_) {
        // Không chặn UI nếu sync fail (offline / rules).
      } finally {
        if (mounted) setState(() => _isSyncing = false);
      }
    });
  }

  Future<void> _scrollToAiSection() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final target = _aiSectionKey.currentContext;
    if (target == null || !target.mounted) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.05,
    );
  }

  Future<void> _askGemini() async {
    final selected = ref.read(pantrySelectionProvider).toList()..sort();
    if (selected.isEmpty) {
      await _showMessage(
        title: 'Chưa chọn nguyên liệu',
        message: 'Hãy chọn ít nhất 1 nguyên liệu rồi bấm gợi ý món mới.',
      );
      return;
    }

    setState(() {
      _isAskingAi = true;
      _aiStatus = 'AI đang nghĩ món cho bạn...';
      _aiSuggestions = const [];
      _savedSuggestionKeys.clear();
    });
    await _scrollToAiSection();

    try {
      final existingNames = ref.read(mealsProvider).maybeWhen(
            data: (meals) => meals.map((m) => m.name).toList(growable: false),
            orElse: () => const <String>[],
          );
      final suggestions = await ref.read(geminiMealServiceProvider).suggestMeals(
            ingredients: selected,
            excludeMealNames: existingNames,
          );
      if (!mounted) return;
      setState(() {
        _aiSuggestions = suggestions;
        _aiStatus = 'AI vừa gợi ý ${suggestions.length} món dành cho bạn';
      });
      await _scrollToAiSection();
    } catch (error) {
      if (!mounted) return;
      setState(() => _aiStatus = null);
      await _showMessage(
        title: 'AI chưa gợi ý được',
        message: _friendlyError(error),
      );
    } finally {
      if (mounted) setState(() => _isAskingAi = false);
    }
  }

  String _friendlyError(Object error) => ErrorMessages.forUser(error);

  Future<void> _showMessage({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  String _suggestionKey(MealModel meal) =>
      '${meal.name.trim().toLowerCase()}|${meal.category.name}';

  String _groupLabel(String groupId) {
    for (final group in PantryIngredients.groups) {
      if (group.id == groupId) return group.label;
    }
    return 'Khác';
  }

  Future<void> _saveAiMeal(MealModel meal) async {
    final key = _suggestionKey(meal);
    if (_savedSuggestionKeys.contains(key)) return;

    try {
      final tags = meal.tags.isEmpty ? const ['Gợi ý'] : meal.tags;
      await ref.read(mealRepositoryProvider).addMeal(
            name: meal.name,
            category: meal.category,
            tags: tags,
            ingredients: meal.ingredients,
          );

      final addedIngredients = await ref
          .read(customPantryIngredientsProvider.notifier)
          .addMissing(meal.ingredients);

      if (!mounted) return;
      setState(() => _savedSuggestionKeys.add(key));

      final buffer = StringBuffer()
        ..writeln('"${meal.name}" đã được thêm vào kho món ăn.');

      if (tags.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('Tag món: ${tags.join(', ')}');
      }

      if (addedIngredients.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('Nguyên liệu mới trên tủ lạnh:');
        for (final item in addedIngredients) {
          final groupId = PantryIngredientClassifier.isValidGroup(item.groupId)
              ? item.groupId
              : PantryIngredientClassifier.classify(item.name);
          buffer.writeln('• ${item.name} (${_groupLabel(groupId)})');
        }
      }

      await _showMessage(
        title: 'Đã lưu',
        message: buffer.toString().trim(),
      );
    } catch (error) {
      if (!mounted) return;
      await _showMessage(
        title: 'Không lưu được',
        message: '$error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(pantrySelectionProvider);
    final matchesAsync = ref.watch(pantryMatchesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Tủ lạnh'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
          Text(
            'Nguyên liệu đang có',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn những gì trong tủ — app sẽ gợi ý món phù hợp.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          const IngredientPicker(),
          const Divider(height: AppSpacing.xl),
          Text(
            selected.isEmpty
                ? 'Món phù hợp'
                : 'Món phù hợp · ${matchesAsync.asData?.value.length ?? 0}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          matchesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: AppLoading(),
            ),
            error: (error, _) => Text(
              ErrorMessages.forUser(error),
              style: TextStyle(color: scheme.error),
            ),
            data: (matches) {
              if (selected.isEmpty) {
                return const _HintBox(
                  icon: Icons.touch_app_outlined,
                  text: 'Chọn nguyên liệu phía trên để xem món có thể nấu.',
                );
              }
              if (matches.isEmpty) {
                return const _HintBox(
                  icon: Icons.search_off_rounded,
                  text:
                      'Chưa khớp món trong kho. Kéo xuống để nhờ AI gợi ý món mới.',
                );
              }
              return MatchResultsPager(matches: matches);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: AppSpacing.xl),
          KeyedSubtree(
            key: _aiSectionKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Gợi ý món bằng AI',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI đề xuất món từ nguyên liệu bạn đang chọn.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _isAskingAi ? null : _askGemini,
                  icon: _isAskingAi
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _isAskingAi ? 'AI đang nghĩ...' : 'Nhờ AI gợi ý',
                  ),
                ),
                if (_aiStatus != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _aiStatus!,
                    style: TextStyle(color: scheme.primary),
                  ),
                ],
                if (_aiSuggestions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  for (final meal in _aiSuggestions)
                    _SuggestionCard(
                      meal: meal,
                      saved: _savedSuggestionKeys.contains(_suggestionKey(meal)),
                      onSave: () => _saveAiMeal(meal),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.meal,
    required this.saved,
    required this.onSave,
  });

  final MealModel meal;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: saved ? 0.45 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meal.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (saved)
                    Text(
                      'Đã lưu',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                meal.category.label,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              if (meal.ingredients.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  meal.ingredients.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (meal.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in meal.tags)
                      Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: saved ? null : onSave,
                  icon: Icon(saved ? Icons.check_rounded : Icons.add_rounded),
                  label: Text(saved ? 'Đã lưu' : 'Lưu vào kho'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
