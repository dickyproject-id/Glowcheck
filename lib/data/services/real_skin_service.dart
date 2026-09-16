import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class RealSkinService {
  Interpreter? _interpreter;
  List<String>? _labels;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode
          .accurate, // Gunakan accurate agar deteksi wajah lebih presisi
      enableLandmarks: false,
      enableClassification: false,
    ),
  );

  RealSkinService() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/skin_model.tflite');
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  // Fungsi Softmax untuk mengubah output mentah menjadi persentase (0.0 - 1.0)
  List<double> _softmax(List<double> input) {
    double maxVal = input.reduce(max);
    List<double> expValues = input.map((e) => exp(e - maxVal)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((e) => e / sumExp).toList();
  }

  Future<Map<String, dynamic>> analyzeRealImage(String imagePath) async {
    if (_interpreter == null || _labels == null) {
      // Coba load lagi jika belum siap
      await _loadModel();
      if (_interpreter == null)
        throw "AI sedang memuat, harap tunggu sebentar.";
    }

    // Menggunakan InputImage dari File (Standard ML Kit terbaru)
    final File imageFile = File(imagePath);
    final inputImage = InputImage.fromFile(imageFile);

    try {
      // 1. Deteksi Wajah
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) {
        throw "Wajah tidak terdeteksi. Pastikan wajah terlihat jelas dan pencahayaan cukup.";
      }
      final Face face = faces.first;

      // 2. Crop Wajah dari Gambar Asli
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) throw "Gagal memproses gambar.";

      // Fix orientasi kamera (penting untuk foto potrait)
      originalImage = img.bakeOrientation(originalImage);

      int x = face.boundingBox.left.toInt();
      int y = face.boundingBox.top.toInt();
      int w = face.boundingBox.width.toInt();
      int h = face.boundingBox.height.toInt();

      // Validasi agar crop tidak error (keluar batas)
      x = max(0, x);
      y = max(0, y);
      if (x + w > originalImage.width) w = originalImage.width - x;
      if (y + h > originalImage.height) h = originalImage.height - y;

      img.Image faceCrop = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: w,
        height: h,
      );

      // 3. Resize ke 224x224 (Standar Model TFLite)
      img.Image resizedImage = img.copyResize(
        faceCrop,
        width: 224,
        height: 224,
      );

      // 4. Konversi ke Input Tensor (Float32 [1, 224, 224, 3])
      // Normalisasi nilai pixel menjadi 0.0 - 1.0 atau -1.0 - 1.0 tergantung training
      // Di sini kita pakai normalisasi standar 0-255 -> 0.0-1.0
      var inputBuffer = List.generate(
        1,
        (i) => List.generate(
          224,
          (y) => List.generate(224, (x) => List.filled(3, 0.0)),
        ),
      );

      for (int py = 0; py < 224; py++) {
        for (int px = 0; px < 224; px++) {
          final pixel = resizedImage.getPixel(px, py);
          inputBuffer[0][py][px][0] = pixel.r / 255.0; // R
          inputBuffer[0][py][px][1] = pixel.g / 255.0; // G
          inputBuffer[0][py][px][2] = pixel.b / 255.0; // B
        }
      }

      // 5. Jalankan Inference
      int outputSize = _labels!.length;
      var outputBuffer = List.filled(
        1 * outputSize,
        0.0,
      ).reshape([1, outputSize]);

      _interpreter!.run(inputBuffer, outputBuffer);

      // 6. Baca Hasil Probabilitas
      List<double> rawScores = List<double>.from(outputBuffer[0]);
      List<double> probabilities = _softmax(rawScores);

      // --- [BAGIAN INI YANG DIPERBAIKI: LOGIKA PRIORITAS] ---

      // Fungsi helper untuk mengambil nilai probabilitas berdasarkan kata kunci label
      double getScore(String keyword) {
        int idx = _labels!.indexWhere((l) => l.toLowerCase().contains(keyword));
        // Jika label ditemukan, kembalikan nilainya. Jika tidak, 0.0
        return (idx != -1) ? probabilities[idx] : 0.0;
      }

      // Ambil skor masing-masing kategori
      double scoreAcne = getScore('jerawat') + getScore('acne');
      double scoreOily =
          getScore('minyak') + getScore('oily') + getScore('oil');
      double scoreDry = getScore('kering') + getScore('dry');
      double scoreNormal = getScore('normal');

      String finalSkinType = 'Normal';

      // LOGIKA UTAMA: PRIORITAS JERAWAT
      // Jika probabilitas jerawat > 35%, kita anggap itu masalah utama
      // meskipun skor minyak mungkin 60% (karena kulit berjerawat seringkali berminyak)
      double acneThreshold = 0.35;

      if (scoreAcne > acneThreshold) {
        finalSkinType = 'Berjerawat';
      }
      // Jika tidak jerawat, baru kita bandingkan skor tertinggi sisanya
      else {
        if (scoreOily > scoreDry && scoreOily > scoreNormal) {
          finalSkinType = 'Berminyak';
        } else if (scoreDry > scoreOily && scoreDry > scoreNormal) {
          finalSkinType = 'Kering';
        } else {
          finalSkinType = 'Normal';
        }
      }

      // Siapkan data detail untuk ditampilkan di UI (Debug purpose)
      Map<String, double> detailsMap = {
        'Jerawat': scoreAcne * 100,
        'Berminyak': scoreOily * 100,
        'Kering': scoreDry * 100,
        'Normal': scoreNormal * 100,
      };

      // 7. Kembalikan Hasil
      return {
        'skinType': finalSkinType,
        'hasMoles':
            (finalSkinType == 'Berjerawat'), // Flag hasMoles true jika jerawat
        'details': detailsMap, // Kirim map skor agar bisa dicek
      };
    } catch (e) {
      print("Error Analysis: $e");
      rethrow; // Lempar error ke UI
    }
  }

  void dispose() {
    _interpreter?.close();
    _faceDetector.close();
  }
}
