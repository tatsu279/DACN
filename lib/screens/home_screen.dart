import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/recognition_service.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/currency_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  String? _detectedCurrency;
  double? _confidence;
  bool _isLoading = false;
  bool _hasError = false;

  final ImagePicker _picker = ImagePicker();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) await _processImage(File(picked.path));
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) await _processImage(File(picked.path));
  }

  Future<void> _processImage(File image) async {
    setState(() {
      _selectedImage = image;
      _isLoading = true;
      _hasError = false;
    });

    final result = await RecognitionService.recognizeImage(image.path);

    if (!mounted) return;

    if (result.label == "Unknown" || result.confidence == 0.0) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _detectedCurrency = result.label;
      _confidence = result.confidence * 100;
      _isLoading = false;
    });

    _fadeController.forward(from: 0);
  }

  void _resetResult() {
    setState(() {
      _selectedImage = null;
      _detectedCurrency = null;
      _confidence = null;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradientBorder = LinearGradient(
      colors: [Colors.teal, Colors.greenAccent.shade100, Colors.white],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // 🪙 Tiêu đề
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on_rounded,
                      color: Colors.teal, size: 34),
                  const SizedBox(width: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.teal, Colors.greenAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      "app_title".tr(),
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 🎛 Hai nút chức năng
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text("capture".tr()),
                      style: ElevatedButton.styleFrom(
                        elevation: 4,
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ).copyWith(
                        overlayColor: MaterialStateProperty.all(
                            Colors.tealAccent.withOpacity(0.2)),
                      ),
                      onPressed: _captureImage,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.image_outlined),
                      label: Text("pick".tr()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Colors.teal, width: 1.5),
                        foregroundColor: Colors.teal.shade900,
                      ),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // 🧭 Khung kết quả
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: gradientBorder,
                  ),
                  padding: const EdgeInsets.all(1.5),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? _buildLoadingState()
                        : _hasError
                            ? _buildErrorState()
                            : _selectedImage == null
                                ? _buildPlaceholder()
                                : _buildResultDisplay(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.white,
          period: const Duration(seconds: 2),
          child: Container(
            width: double.infinity,
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 180),
            const CircularProgressIndicator(color: Colors.teal, strokeWidth: 4),
            const SizedBox(height: 60),
            Text(
              "loading".tr(),
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_search_rounded,
            size: 90, color: Colors.grey.withOpacity(0.6)),
        const SizedBox(height: 14),
        Text(
          "result_title".tr(),
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "result_sub".tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 90, color: Colors.redAccent),
        const SizedBox(height: 14),
        Text(
          "error_title".tr(),
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          "error_sub".tr(),
          style: const TextStyle(fontSize: 15, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _resetResult,
          icon: const Icon(Icons.refresh),
          label: Text("retry".tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          ),
        )
      ],
    );
  }

  Widget _buildResultDisplay() {
    final rawLabel = _detectedCurrency ?? "";
    final localeCode = context.locale.languageCode;

    final displayLabel = formatCurrencyLabel(rawLabel, localeCode);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: "detectedImage",
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _selectedImage!,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 🔹 Hiển thị tên tiền đúng format
          Text(
            displayLabel,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),

          const SizedBox(height: 6),

          // 🔹 Độ tin cậy
          Text(
            "${'confidence'.tr()}: ${_confidence?.toStringAsFixed(1) ?? '--'}%",
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
