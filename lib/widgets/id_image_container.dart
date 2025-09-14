import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/id_camera_service.dart';

class IdImageContainer extends StatelessWidget {
  final String? imageUrl;
  final ValueNotifier<String> selectedDiscountSpecification;
  final ValueNotifier<String?> selectedIdImageUrl;

  const IdImageContainer({
    super.key,
    required this.imageUrl,
    required this.selectedDiscountSpecification,
    required this.selectedIdImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00CC58).withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IdImageHeader(
            isDarkMode: isDarkMode,
            selectedDiscountSpecification: selectedDiscountSpecification,
            selectedIdImageUrl: selectedIdImageUrl,
          ),
          const SizedBox(height: 12),
          IdImageDisplay(
            imageUrl: imageUrl,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 8),
          IdImageSuccessIndicator(
            selectedDiscountSpecification: selectedDiscountSpecification,
          ),
        ],
      ),
    );
  }
}

class IdImageHeader extends StatelessWidget {
  final bool isDarkMode;
  final ValueNotifier<String> selectedDiscountSpecification;
  final ValueNotifier<String?> selectedIdImageUrl;

  const IdImageHeader({
    super.key,
    required this.isDarkMode,
    required this.selectedDiscountSpecification,
    required this.selectedIdImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.verified_user,
          color: const Color(0xFF00CC58),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'ID Verification',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        const Spacer(),
        IdImageMenuButton(
          isDarkMode: isDarkMode,
          selectedDiscountSpecification: selectedDiscountSpecification,
          selectedIdImageUrl: selectedIdImageUrl,
        ),
      ],
    );
  }
}

class IdImageMenuButton extends StatelessWidget {
  final bool isDarkMode;
  final ValueNotifier<String> selectedDiscountSpecification;
  final ValueNotifier<String?> selectedIdImageUrl;

  const IdImageMenuButton({
    super.key,
    required this.isDarkMode,
    required this.selectedDiscountSpecification,
    required this.selectedIdImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: isDarkMode ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
      ),
      onSelected: (value) async {
        if (value == 'retake') {
          final currentDiscount = selectedDiscountSpecification.value;
          final newImageUrl = await IdCameraService.captureAndUploadIdImage(
            context: context,
            passengerType: currentDiscount,
          );
          if (newImageUrl != null) {
            selectedIdImageUrl.value = newImageUrl;
          }
        } else if (value == 'remove') {
          selectedIdImageUrl.value = null;
          selectedDiscountSpecification.value = '';
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'retake',
          child: Row(
            children: [
              Icon(Icons.camera_alt, size: 18),
              SizedBox(width: 8),
              Text('Retake Photo'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Remove', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

class IdImageDisplay extends StatelessWidget {
  final String? imageUrl;
  final bool isDarkMode;

  const IdImageDisplay({
    super.key,
    required this.imageUrl,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFF0F0F0),
        ),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: const Color(0xFF00CC58),
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loading image...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      color: isDarkMode
                          ? const Color(0xFFAAAAAA)
                          : const Color(0xFF666666),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No image available',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? const Color(0xFFAAAAAA)
                            : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class IdImageSuccessIndicator extends StatelessWidget {
  final ValueNotifier<String> selectedDiscountSpecification;

  const IdImageSuccessIndicator({
    super.key,
    required this.selectedDiscountSpecification,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          color: const Color(0xFF00CC58),
          size: 16,
        ),
        const SizedBox(width: 6),
        ValueListenableBuilder<String>(
          valueListenable: selectedDiscountSpecification,
          builder: (context, discount, _) => Text(
            '$discount ID uploaded successfully.',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF00CC58),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
