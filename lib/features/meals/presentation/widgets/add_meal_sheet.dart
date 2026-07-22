import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/meal_category.dart';
import '../../../../core/models/meal_model.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../pantry/presentation/providers/pantry_provider.dart';
import '../providers/meals_provider.dart';

/// Bottom sheet form thêm / sửa món ăn.
class MealFormSheet extends ConsumerStatefulWidget {
  const MealFormSheet({super.key, this.meal});

  /// `null` = thêm mới; có giá trị = chỉnh sửa.
  final MealModel? meal;

  static Future<bool?> show(
    BuildContext context, {
    MealModel? meal,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => MealFormSheet(meal: meal),
    );
  }

  @override
  ConsumerState<MealFormSheet> createState() => _MealFormSheetState();
}

class _MealFormSheetState extends ConsumerState<MealFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _tagsController;
  late final TextEditingController _ingredientsController;

  late MealCategory _category;
  bool _isSaving = false;

  bool get _isEditing => widget.meal != null;

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    _nameController = TextEditingController(text: meal?.name ?? '');
    _tagsController = TextEditingController(
      text: meal?.tags.join(', ') ?? '',
    );
    _ingredientsController = TextEditingController(
      text: meal?.ingredients.join(', ') ?? '',
    );
    _category = meal?.category ?? MealCategory.lunch;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  List<String> _parseCsv(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    final tags = _parseCsv(_tagsController.text);
    final ingredients = _parseCsv(_ingredientsController.text);

    try {
      final repo = ref.read(mealRepositoryProvider);
      if (_isEditing) {
        final updated = widget.meal!.copyWith(
          name: _nameController.text.trim(),
          category: _category,
          tags: tags,
          ingredients: ingredients,
        );
        await repo.updateMeal(updated);
      } else {
        await repo.addMeal(
          name: _nameController.text,
          category: _category,
          tags: tags,
          ingredients: ingredients,
        );
      }

      if (ingredients.isNotEmpty) {
        await ref
            .read(customPantryIngredientsProvider.notifier)
            .addMissing(ingredients);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Không cập nhật được món: $error'
                : 'Không thêm được món: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Sửa món ăn' : 'Thêm món mới',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tên món',
                  hintText: 'Ví dụ: Bún thịt nướng',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập tên món ăn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<MealCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                ),
                items: MealCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _category = value);
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _tagsController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tags (tuỳ chọn)',
                  hintText: 'Nóng, Món nước, 35k-50k',
                  helperText: 'Phân tách bằng dấu phẩy',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _ingredientsController,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nguyên liệu (tuỳ chọn)',
                  hintText: 'Thịt bò, Lá lốt, Hành tím',
                  helperText:
                      'Phân tách bằng dấu phẩy — sẽ hiện trên Tủ lạnh còn gì nếu chưa có',
                  prefixIcon: Icon(Icons.kitchen_outlined),
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEditing ? Icons.save_outlined : Icons.add),
                label: Text(
                  _isSaving
                      ? 'Đang lưu...'
                      : (_isEditing ? 'Lưu thay đổi' : 'Thêm món'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias giữ tương thích chỗ gọi cũ.
typedef AddMealSheet = MealFormSheet;
