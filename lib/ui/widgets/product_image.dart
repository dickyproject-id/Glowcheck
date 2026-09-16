import 'dart:convert'; // For Base64

import 'package:flutter/material.dart';
import 'package:glowcheck/core/theme.dart';

class ProductImage extends StatelessWidget {
  final String imageSource;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ProductImage({
    super.key,
    required this.imageSource,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Check if Base64 (Usually a long string without path/extension)
    if (imageSource.length > 500 || !imageSource.contains('/')) {
      try {
        return Image.memory(
          base64Decode(imageSource),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (c, e, s) =>
              _buildErrorIcon(Icons.broken_image_rounded),
        );
      } catch (e) {
        return _buildErrorIcon(Icons.error_outline_rounded);
      }
    }

    // 2. Check if Asset (starts with assets/)
    if (imageSource.startsWith('assets/')) {
      return Image.asset(
        imageSource,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (c, e, s) =>
            _buildErrorIcon(Icons.image_not_supported_rounded),
      );
    }

    // 3. Check if Online URL (http/https)
    if (imageSource.startsWith('http')) {
      return Image.network(
        imageSource,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              color: AppColors.deepTeal, // Updated to Deep Teal
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (c, e, s) => _buildErrorIcon(Icons.wifi_off_rounded),
      );
    }

    // 4. Fallback Default
    return _buildErrorIcon(Icons.image_rounded);
  }

  // Helper to build consistent & aesthetic Error Icons
  Widget _buildErrorIcon(IconData icon) {
    return Container(
      width: width,
      height: height,
      color: AppColors.softGrey.withOpacity(0.3), // Soft Grey Background
      child: Center(
        child: Icon(
          icon,
          color: AppColors.mustard.withOpacity(
            0.6,
          ), // Mustard color for icons (pop!)
          size: 30,
        ),
      ),
    );
  }
}
