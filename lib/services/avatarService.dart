import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service for managing avatar images in private Supabase Storage
class AvatarService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'avatars';
  static const Uuid _uuid = Uuid();

  /// Initialize the avatar storage bucket (call this once during app initialization)
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
            allowedMimeTypes: [
              'image/jpeg',
              'image/png',
              'image/jpg',
              'image/webp'
            ],
            fileSizeLimit: '10485760', // 10MB limit as string
          ),
        );
        debugPrint('Created avatar storage bucket');
      }
    } catch (e) {
      debugPrint('Error initializing avatar storage bucket: $e');
      // Don't throw - bucket might already exist or user might not have permissions
    }
  }

  /// Upload avatar image to private Supabase Storage
  /// Returns a signed URL that can be used to display the image
  static Future<String?> uploadAvatar({
    required File imageFile,
    String? userId,
  }) async {
    try {
      // Ensure bucket exists before uploading
      await initializeBucket();

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final targetUserId = userId ?? user.id;

      // Validate file size (10MB limit)
      final fileSizeInBytes = await imageFile.length();
      const maxSizeInBytes = 10 * 1024 * 1024;
      if (fileSizeInBytes > maxSizeInBytes) {
        throw Exception('Image file too large. Maximum size is 10MB.');
      }

      // Validate file type
      final fileName = imageFile.path.split('/').last.toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      final hasValidExtension =
          allowedExtensions.any((ext) => fileName.endsWith(ext));
      if (!hasValidExtension) {
        throw Exception(
            'Invalid file type. Only JPG, JPEG, PNG, and WebP files are allowed.');
      }

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = _uuid.v4();
      final fileExtension = fileName.split('.').last;
      final uploadFileName =
          '$targetUserId/avatar_$timestamp$uniqueId.$fileExtension';

      // Upload to Supabase Storage
      final uploadPath = await _supabase.storage.from(_bucketName).upload(
            uploadFileName,
            imageFile,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExtension),
              metadata: {
                'user_id': targetUserId,
                'upload_timestamp': timestamp.toString(),
                'original_filename': fileName,
                'file_type': 'avatar',
              },
            ),
          );

      debugPrint('Avatar uploaded successfully: $uploadPath');

      // Return the file path (not a signed URL yet)
      // The signed URL will be generated when needed for display
      return uploadFileName;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  /// Get a signed URL for displaying an avatar image
  /// This should be called when displaying the image in the UI
  static Future<String?> getAvatarSignedUrl({
    required String avatarPath,
    int expiryInSeconds = 3600, // 1 hour default
  }) async {
    try {
      // If it's already a full URL (legacy public URLs), return as is
      if (avatarPath.startsWith('http')) {
        return avatarPath;
      }

      // If it's a default asset path, return as is
      if (avatarPath.startsWith('assets/')) {
        return avatarPath;
      }

      // Generate signed URL for private storage
      final signedUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(avatarPath, expiryInSeconds);

      return signedUrl;
    } catch (e) {
      debugPrint('Error getting avatar signed URL: $e');
      return null;
    }
  }

  /// Delete an avatar image from storage
  static Future<bool> deleteAvatar(String avatarPath) async {
    try {
      // Extract just the file path if it's a full URL
      final filePath = _extractFilePathFromUrl(avatarPath);
      if (filePath == null) return false;

      await _supabase.storage.from(_bucketName).remove([filePath]);
      debugPrint('Avatar deleted successfully: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error deleting avatar: $e');
      return false;
    }
  }

  /// List all avatars for a specific user
  static Future<List<FileObject>> getUserAvatars(String userId) async {
    try {
      final files =
          await _supabase.storage.from(_bucketName).list(path: userId);
      return files;
    } catch (e) {
      debugPrint('Error listing user avatars: $e');
      return [];
    }
  }

  /// Cleanup old avatars (keep only the latest one per user)
  static Future<void> cleanupOldAvatars(String userId) async {
    try {
      final avatars = await getUserAvatars(userId);

      if (avatars.length > 1) {
        // Sort by creation time (newest first)
        avatars.sort((a, b) => DateTime.parse(b.createdAt ?? '')
            .compareTo(DateTime.parse(a.createdAt ?? '')));

        // Delete all except the newest one
        final avatarsToDelete =
            avatars.skip(1).map((avatar) => '$userId/${avatar.name}').toList();

        if (avatarsToDelete.isNotEmpty) {
          await _supabase.storage.from(_bucketName).remove(avatarsToDelete);
          debugPrint(
              'Cleaned up ${avatarsToDelete.length} old avatars for user $userId');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old avatars: $e');
    }
  }

  /// Extract file path from Supabase URL for storage operations
  static String? _extractFilePathFromUrl(String url) {
    try {
      // If it's not a URL, assume it's already a file path
      if (!url.startsWith('http')) {
        return url;
      }

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
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  /// Check if an avatar path is a private storage path
  static bool isPrivateStoragePath(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return false;

    // Check if it's a default asset path
    if (avatarPath.startsWith('assets/')) return false;

    // Check if it's a public URL (legacy)
    if (avatarPath.startsWith('http')) return false;

    // If it's just a file path, it's likely from private storage
    return true;
  }
}
