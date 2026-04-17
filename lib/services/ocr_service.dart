import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'local_ai_engine.dart';

class OCRService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final LocalAIEngine _aiEngine = LocalAIEngine();

  /// Picks an image from camera or gallery, performs OCR, and extracts structured data.
  Future<Map<String, dynamic>?> scanReceipt(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return null;

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text;
      
      if (fullText.trim().isEmpty) {
        return {
          'error': 'Tidak ada teks yang terdeteksi pada struk.',
          'amount': 0.0,
          'category': 'Lainnya',
          'title': 'Transaksi Scan'
        };
      }

      // Use AI Engine to parse the raw text
      final result = _aiEngine.extractReceiptData(fullText);
      return result;

    } catch (e) {
      return {
        'error': 'Gagal memproses struk: $e',
        'amount': 0.0,
        'category': 'Lainnya',
        'title': 'Transaksi Scan'
      };
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
