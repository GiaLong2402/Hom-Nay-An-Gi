import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/gemini_config.dart';
import '../../../core/models/meal_category.dart';
import '../../../core/models/meal_model.dart';
import '../../../core/utils/error_messages.dart';

/// Gợi ý món từ AI dựa trên nguyên liệu tủ lạnh.
class GeminiMealService {
  /// Gemini 3.5 Flash — gọi REST để set thinkingLevel (tránh treo JSON).
  static const _modelName = 'gemini-3.5-flash';
  static const _timeout = Duration(seconds: 45);

  String get _apiKey {
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return GeminiConfig.apiKey.trim();
  }

  Future<List<MealModel>> suggestMeals({
    required List<String> ingredients,
    List<String> excludeMealNames = const [],
  }) async {
    final key = _apiKey;
    if (key.isEmpty) {
      throw StateError('Chưa cấu hình AI API key.');
    }
    if (ingredients.isEmpty) {
      throw StateError('Hãy chọn ít nhất 1 nguyên liệu trước.');
    }

    final exclude = excludeMealNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    final excludeBlock = exclude.isEmpty
        ? ''
        : '''
Các món ĐÃ CÓ trong app (KHÔNG được gợi ý lại, kể cả tên gần giống):
${exclude.map((name) => '- $name').join('\n')}
''';

    final prompt = '''
Bạn là trợ lý nấu ăn Việt Nam.
Người dùng đang có các nguyên liệu: ${ingredients.join(', ')}.

Hãy gợi ý ĐÚNG 3 món ăn Việt:
- Ưu tiên món CHƯA có trong danh sách bên dưới (món mới / ít phổ biến hơn cũng được).
- Có thể nấu từ nguyên liệu trên (được thiếu 1-2 nguyên liệu phụ).
- Tên món phải khác hẳn các món đã có.
$excludeBlock
Trả về JSON array (không markdown), mỗi phần tử:
{
  "name": "Tên món",
  "category": "Một trong: Sáng, Trưa, Tối, Đồ khô, Đồ nước, Ăn vặt",
  "ingredients": ["nguyên liệu 1", "nguyên liệu 2"],
  "tags": ["nhanh", "dễ làm"]
}
''';

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_modelName:generateContent',
    );

    final body = <String, dynamic>{
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        // 3.5 Flash mặc định thinking medium — dễ treo khi kèm JSON.
        'thinkingConfig': {
          'thinkingLevel': 'minimal',
        },
      },
    };

    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': key,
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw StateError(
        'AI phản hồi quá chậm. Kiểm tra mạng rồi thử lại.',
      );
    } on http.ClientException catch (error) {
      throw StateError(ErrorMessages.forUser(error));
    } catch (error) {
      throw StateError(ErrorMessages.forUser(error));
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_friendlyHttpError(response.statusCode, response.body));
    }

    try {
      final text = _extractText(response.body);
      if (text == null || text.trim().isEmpty) {
        throw StateError('AI không trả về nội dung. Thử lại lần nữa.');
      }

      final meals = _parseMeals(text);
      final fresh = meals
          .where((meal) => !_isExcluded(meal.name, exclude))
          .toList(growable: false);
      if (fresh.isEmpty) {
        throw StateError('Gợi ý trùng với món đã có trong app. Thử lại.');
      }
      return fresh;
    } on FormatException {
      throw StateError('AI trả dữ liệu lỗi. Thử lại lần nữa.');
    }
  }

  String _friendlyHttpError(int statusCode, String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        final error = json['error'];
        if (error is Map) {
          final message = error['message']?.toString() ?? '';
          if (statusCode == 401 || statusCode == 403) {
            return 'API key không hợp lệ hoặc hết quyền. Tạo key mới trên AI Studio.';
          }
          if (statusCode == 429) {
            return 'AI đang quá tải / hết hạn mức. Đợi vài phút rồi thử lại.';
          }
          if (statusCode == 404) {
            return 'Model AI không khả dụng với key hiện tại.';
          }
          if (message.isNotEmpty) {
            return message.length > 180
                ? '${message.substring(0, 180)}…'
                : message;
          }
        }
      }
    } catch (_) {}
    return 'AI gặp sự cố (mã $statusCode). Thử lại sau.';
  }

  /// Lấy text thường, bỏ qua phần thinking nếu có.
  String? _extractText(String rawBody) {
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map<String, dynamic>) return null;

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final first = candidates.first;
    if (first is! Map) return null;
    final content = first['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List) return null;

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is! Map) continue;
      if (part['thought'] == true) continue;
      final text = part['text'];
      if (text is String && text.trim().isNotEmpty) {
        buffer.write(text);
      }
    }
    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  bool _isExcluded(String name, Set<String> exclude) {
    final normalized = _normalizeName(name);
    for (final existing in exclude) {
      if (_normalizeName(existing) == normalized) return true;
    }
    return false;
  }

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<MealModel> _parseMeals(String raw) {
    var payload = raw.trim();
    if (payload.startsWith('```')) {
      payload = payload
          .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: false), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }

    final decoded = jsonDecode(payload);
    final List items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      final nested =
          decoded['meals'] ?? decoded['suggestions'] ?? decoded['data'];
      if (nested is! List) {
        throw const FormatException('JSON gợi ý phải là một mảng.');
      }
      items = nested;
    } else {
      throw const FormatException('JSON gợi ý phải là một mảng.');
    }

    final meals = items.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return MealModel(
        id: '',
        name: (map['name'] as String?)?.trim() ?? 'Món gợi ý',
        category: MealCategory.fromString(map['category'] as String?),
        tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ??
            const ['Gợi ý'],
        ingredients: (map['ingredients'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        isEnabled: true,
        isCustom: true,
        createdAt: DateTime.now(),
      );
    }).toList(growable: false);

    if (meals.isEmpty) {
      throw const FormatException('AI trả JSON nhưng không có món nào.');
    }
    return meals;
  }
}
