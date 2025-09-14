import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service for uploading and managing ID images using Supabase Storage
class IdImageUploadService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'id-verification';
  static const Uuid _uuid = Uuid();

  /// Initialize the storage bucket (call this once during app initialization)
  static Future<void> initializeBucket() async {
    try {
      // Check if bucket exists, create if it doesn't
      final buckets = await _supabase.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.name == _bucketName);

      if (!bucketExists) {
        await _supabase.storage.createBucket(
          _bucketName,
          BucketOptions(
            public: false, // Private bucket for security
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/jpg'],
            fileSizeLimit: '5242880', // 5MB limit as string
          ),
        );
        debugPrint('Created ID verification storage bucket');
      }
    } catch (e) {
      debugPrint('Error initializing storage bucket: $e');
      // Don't throw - bucket might already exist or user might not have permissions
    }
  }

  static Future<String?> uploadIdImage({
    required File imageFile,
    required String passengerType,
    String? bookingId,
  }) async {
    try {
      // Ensure bucket exists before uploading
      await initializeBucket();

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate file size (5MB limit)
      final fileSizeInBytes = await imageFile.length();
      const maxSizeInBytes = 5 * 1024 * 1024;
      if (fileSizeInBytes > maxSizeInBytes) {
        throw Exception('Image file too large. Maximum size is 5MB.');
      }

      // Validate file type
      final fileName = path.basename(imageFile.path).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png'];
      final hasValidExtension =
          allowedExtensions.any((ext) => fileName.endsWith(ext));
      if (!hasValidExtension) {
        throw Exception(
            'Invalid file type. Only JPG, JPEG, and PNG files are allowed.');
      }

      // Generate unique file name with metadata
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = _uuid.v4();
      final fileExtension = path.extension(fileName);
      final uploadFileName =
          '${user.id}/${passengerType}_${timestamp}_$uniqueId$fileExtension';

      // Read file bytes
      final Uint8List fileBytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      final uploadPath = await _supabase.storage.from(_bucketName).uploadBinary(
            uploadFileName,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExtension),
              metadata: {
                'passenger_id': user.id,
                'passenger_type': passengerType,
                'booking_id': bookingId ?? '',
                'upload_timestamp': timestamp.toString(),
                'original_filename': fileName,
              },
            ),
          );

      debugPrint('ID image uploaded successfully: $uploadPath');

      // Get the public URL (signed URL for private bucket)
      final signedUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(uploadFileName, 60 * 60 * 24 * 365); // 1 year expiry

      return signedUrl;
    } catch (e) {
      debugPrint('Error uploading ID image: $e');

      // Provide specific guidance for common errors
      if (e.toString().contains('Bucket not found')) {
        debugPrint('Storage bucket not found. Please create it manually:');
        debugPrint('1. Go to your Supabase Dashboard');
        debugPrint('2. Navigate to Storage');
        debugPrint('3. Create a new bucket named: $_bucketName');
        debugPrint('4. Set it as private with 5MB file size limit');
        debugPrint(
            '5. Add allowed MIME types: image/jpeg, image/png, image/jpg');
      }

      return null;
    }
  }

  /// Get a signed URL for an existing image (for viewing)
  static Future<String?> getSignedUrl({
    required String imagePath,
    int expiryInSeconds = 3600, // 1 hour default
  }) async {
    try {
      final signedUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(imagePath, expiryInSeconds);
      return signedUrl;
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      return null;
    }
  }

  /// Delete an ID image from storage
  static Future<bool> deleteIdImage(String imagePath) async {
    try {
      await _supabase.storage.from(_bucketName).remove([imagePath]);
      debugPrint('ID image deleted successfully: $imagePath');
      return true;
    } catch (e) {
      debugPrint('Error deleting ID image: $e');
      return false;
    }
  }

  /// List all ID images for the current user
  static Future<List<FileObject>> getUserIdImages() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final files =
          await _supabase.storage.from(_bucketName).list(path: user.id);

      return files;
    } catch (e) {
      debugPrint('Error listing user ID images: $e');
      return [];
    }
  }

  /// Get image metadata
  static Future<Map<String, dynamic>?> getImageMetadata(
      String imagePath) async {
    try {
      final files = await _supabase.storage.from(_bucketName).list();

      final file = files.firstWhere(
        (f) => f.name == imagePath,
        orElse: () => throw Exception('File not found'),
      );

      return file.metadata;
    } catch (e) {
      debugPrint('Error getting image metadata: $e');
      return null;
    }
  }

  /// Extract file path from Supabase URL for storage operations
  static String? extractFilePathFromUrl(String url) {
    try {
      // Extract the file path from the signed URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find the bucket name in the path and get everything after it
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        return pathSegments.sublist(bucketIndex + 1).join('/');
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting file path from URL: $e');
      return null;
    }
  }

  /// Helper method to get content type based on file extension
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  /// Cleanup old ID images (older than specified days)
  static Future<void> cleanupOldImages({int olderThanDays = 30}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final files = await getUserIdImages();
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

      final filesToDelete = <String>[];
      for (final file in files) {
        if (file.createdAt != null) {
          DateTime? fileDate;
          if (file.createdAt is String) {
            try {
              fileDate = DateTime.parse(file.createdAt as String);
            } catch (e) {
              continue; // Skip if date parsing fails
            }
          } else if (file.createdAt is DateTime) {
            fileDate = file.createdAt as DateTime;
          }

          if (fileDate != null && fileDate.isBefore(cutoffDate)) {
            filesToDelete.add('${user.id}/${file.name}');
          }
        }
      }

      if (filesToDelete.isNotEmpty) {
        await _supabase.storage.from(_bucketName).remove(filesToDelete);
        debugPrint('Cleaned up ${filesToDelete.length} old ID images');
      }
    } catch (e) {
      debugPrint('Error cleaning up old images: $e');
    }
  }
}
