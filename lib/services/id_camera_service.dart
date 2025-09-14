import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasada_passenger_app/services/id_image_upload_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling ID camera capture and permissions
class IdCameraService {
  static final ImagePicker _picker = ImagePicker();

  /// Captures an ID image with proper permissions handling and uploads to Supabase
  /// Returns the uploaded image URL instead of local file
  static Future<String?> captureAndUploadIdImage({
    required BuildContext context,
    required String passengerType,
    String? bookingId,
  }) async {
    try {
      // Request camera permission
      final cameraPermission = await Permission.camera.request();

      if (cameraPermission.isDenied) {
        _showPermissionDialog(context);
        return null;
      }

      if (cameraPermission.isPermanentlyDenied) {
        _showSettingsDialog(context);
        return null;
      }

      // Show capture instructions before opening camera
      final shouldProceed = await _showCaptureInstructionsDialog(context);
      if (!shouldProceed) {
        return null;
      }

      // Capture image using camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Optimize image size while maintaining quality
        maxWidth: 1080,
        maxHeight: 1080,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Validate image size (should be reasonable for ID)
        final int fileSizeInBytes = await imageFile.length();
        const int maxSizeInBytes = 5 * 1024 * 1024; // 5MB limit

        if (fileSizeInBytes > maxSizeInBytes) {
          Fluttertoast.showToast(
            msg: "Image file too large. Please try again.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Color(0xFFF5F5F5),
          );
          return null;
        }

        // Show uploading toast
        Fluttertoast.showToast(
          msg: "Uploading ID image...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF00CC58),
          textColor: Color(0xFFF5F5F5),
        );

        // Upload to Supabase Storage
        final uploadedUrl = await IdImageUploadService.uploadIdImage(
          imageFile: imageFile,
          passengerType: passengerType,
          bookingId: bookingId,
        );

        if (uploadedUrl != null) {
          // Clean up local file after successful upload
          try {
            await imageFile.delete();
          } catch (e) {
            // Ignore deletion errors - file might already be cleaned up
          }

          Fluttertoast.showToast(
            msg: "ID image uploaded successfully!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: const Color(0xFF00CC58),
            textColor: Color(0xFFF5F5F5),
          );

          return uploadedUrl;
        } else {
          _showErrorToast("Failed to upload image. Please try again.");
          return null;
        }
      }

      return null;
    } catch (e) {
      _showErrorToast("Failed to capture and upload image. Please try again.");
      return null;
    }
  }

  /// Legacy method for backward compatibility - captures local image only
  @deprecated
  static Future<File?> captureIdImage(BuildContext context) async {
    try {
      // Request camera permission
      final cameraPermission = await Permission.camera.request();

      if (cameraPermission.isDenied) {
        _showPermissionDialog(context);
        return null;
      }

      if (cameraPermission.isPermanentlyDenied) {
        _showSettingsDialog(context);
        return null;
      }

      // Show capture instructions before opening camera
      final shouldProceed = await _showCaptureInstructionsDialog(context);
      if (!shouldProceed) {
        return null;
      }

      // Capture image using camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Optimize image size while maintaining quality
        maxWidth: 1080,
        maxHeight: 1080,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Validate image size (should be reasonable for ID)
        final int fileSizeInBytes = await imageFile.length();
        const int maxSizeInBytes = 5 * 1024 * 1024; // 5MB limit

        if (fileSizeInBytes > maxSizeInBytes) {
          Fluttertoast.showToast(
            msg: "Image file too large. Please try again.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Color(0xFFF5F5F5),
          );
          return null;
        }

        return imageFile;
      }

      return null;
    } catch (e) {
      _showErrorToast("Failed to capture image. Please try again.");
      return null;
    }
  }

  /// Shows permission dialog when camera access is denied
  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Camera Permission Required',
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'To verify your discount eligibility, we need access to your camera to take a photo of your valid ID.',
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFAAAAAA)
                  : const Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                captureIdImage(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CC58),
                foregroundColor: Color(0xFFF5F5F5),
              ),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );
  }

  /// Shows settings dialog when permission is permanently denied
  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Permission Required',
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Camera access is required to verify your ID. Please enable it in Settings.',
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFAAAAAA)
                  : const Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CC58),
                foregroundColor: Colors.white,
              ),
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Shows capture instructions dialog
  static Future<bool> _showCaptureInstructionsDialog(
      BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          title: Row(
            children: [
              const Icon(
                Icons.camera_alt,
                color: Color(0xFF00CC58),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'ID Photo Capture',
                style: TextStyle(
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please ensure:',
                style: TextStyle(
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildInstructionItem(
                '• ID is clearly visible and well-lit',
                isDarkMode,
              ),
              _buildInstructionItem(
                '• All text is readable',
                isDarkMode,
              ),
              _buildInstructionItem(
                '• Photo shows the entire ID',
                isDarkMode,
              ),
              _buildInstructionItem(
                '• ID is not expired',
                isDarkMode,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CC58).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00CC58).withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: Color(0xFF00CC58),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your ID will be securely processed for verification only.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? const Color(0xFFF5F5F5)
                              : const Color(0xFF121212),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CC58),
                foregroundColor: Colors.white,
              ),
              child: const Text('Take Photo'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  static Widget _buildInstructionItem(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
        ),
      ),
    );
  }

  static void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}
