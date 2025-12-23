import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// ==============================================
/// 🔹 DỊCH VỤ NHẬN DIỆN TIỀN TỆ VIỆT NAM
/// ==============================================
class RecognitionService {
  static Interpreter? _interpreter;
  static List<String> _labels = [];
  static bool _isLoaded = false;

  /// 🧠 Load mô hình TFLite và labels
  static Future<void> loadModel() async {
    if (_isLoaded) return;

    try {
      print("🚀 Đang khởi động và load model...");
      final appDir = await getApplicationDocumentsDirectory();
      final modelPath = '${appDir.path}/final_model.tflite';

      // ✅ Copy model từ assets nếu chưa có
      if (!File(modelPath).existsSync()) {
        final data = await rootBundle.load('assets/final_model.tflite');
        await File(modelPath).writeAsBytes(data.buffer.asUint8List());
      }

      // ✅ Load model
      _interpreter = Interpreter.fromFile(File(modelPath));
      _interpreter!.allocateTensors();
      _isLoaded = true;
      print("✅ Model loaded thành công!");
      print(
          "🔍 Output tensor shape: ${_interpreter!.getOutputTensor(0).shape}");

      // 🏷️ Load labels
      try {
        final labelData = await rootBundle.loadString('assets/labels.txt');
        _labels = labelData
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        print("🏷️ Labels loaded: ${_labels.length} lớp");
      } catch (e) {
        print("⚠️ Không tìm thấy labels.txt, dùng nhãn mặc định.");
        _labels = ["Unknown"];
      }
    } catch (e) {
      print("❌ Lỗi khi load model: $e");
    }
  }

  /// 🔍 Nhận diện ảnh (chỉ chạy khi người dùng chọn/chụp)
  static Future<_RecognitionResult> recognizeImage(String? imagePath) async {
    if (!_isLoaded) await loadModel();

    // ⚠️ Ngăn gọi sớm hoặc rỗng path
    if (imagePath == null || imagePath.isEmpty) {
      print("⚠️ Không có đường dẫn ảnh → bỏ qua nhận diện.");
      return _RecognitionResult(label: "Unknown", confidence: 0.0);
    }

    try {
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        print("⚠️ File ảnh không tồn tại: $imagePath");
        return _RecognitionResult(label: "Unknown", confidence: 0.0);
      }

      // 🖼️ Decode ảnh
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception("Ảnh không hợp lệ hoặc hỏng.");

      // Resize về đúng kích thước model
      final resized = img.copyResize(image, width: 260, height: 260);

      // 🔢 Chuẩn bị input float32 (đã normalize 0–1)
      final input = Float32List(1 * 260 * 260 * 3);
      int pixelIndex = 0;
      for (int y = 0; y < 260; y++) {
        for (int x = 0; x < 260; x++) {
          final pixel = resized.getPixel(x, y);
          input[pixelIndex++] = (pixel.r / 255);
          input[pixelIndex++] = (pixel.g / 255);
          input[pixelIndex++] = (pixel.b / 255);
        }
      }

      // 🔸 Chuẩn bị output
      final output = Float32List(_labels.isNotEmpty ? _labels.length : 10);

      // 🧠 Chạy mô hình
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      final inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;

      final inputs = input.reshape(inputShape);
      final outputs = output.reshape(outputShape);

      _interpreter!.run(inputs, outputs);

      print("📊 Raw output: ${outputs[0]}");

      // Tìm kết quả có xác suất cao nhất
      final probs = outputs[0];
      double maxProb = probs[0];
      int maxIndex = 0;

      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          maxIndex = i;
        }
      }

      // ✅ Nếu xác suất quá thấp, xem là không nhận được
      // if (maxProb < 0.4) {
      //   print(
      //       "⚠️ Xác suất thấp (${(maxProb * 100).toStringAsFixed(1)}%), bỏ qua.");
      //   return _RecognitionResult(label: "Unknown", confidence: maxProb);
      // }

      final label = (maxIndex < _labels.length) ? _labels[maxIndex] : "Unknown";

      // 🧠 Không lọc xác suất thấp trong giai đoạn debug
      print("🔍 Dự đoán: $label (${(maxProb * 100).toStringAsFixed(2)}%)");

      return _RecognitionResult(label: label, confidence: maxProb);
    } catch (e) {
      print("❌ Lỗi khi nhận diện ảnh: $e");
      return _RecognitionResult(label: "Unknown", confidence: 0.0);
    }
  }

  /// 🧹 Giải phóng bộ nhớ
  static void close() {
    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
      _isLoaded = false;
      print("🧹 Interpreter closed.");
    }
  }
}

/// ==============================================
/// Kết quả trả về gọn gàng
/// ==============================================
class _RecognitionResult {
  final String label;
  final double confidence;
  _RecognitionResult({required this.label, required this.confidence});
}
