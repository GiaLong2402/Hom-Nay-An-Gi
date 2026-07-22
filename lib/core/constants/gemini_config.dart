/// Cấu hình Gemini cho app (dùng local / MVP).
///
/// Không commit API key thật. Chạy với:
/// `flutter run --dart-define=GEMINI_API_KEY=your_key`
/// hoặc dán key tạm vào đây khi dev local (đừng push).
abstract final class GeminiConfig {
  static const apiKey = '';
}
