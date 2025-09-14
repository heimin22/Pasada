import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/avatarService.dart';

/// Widget for displaying avatar images with automatic signed URL handling
class AvatarImage extends StatefulWidget {
  final String? avatarPath;
  final double? size;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const AvatarImage({
    super.key,
    this.avatarPath,
    this.size,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage> {
  String? _signedUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAvatarUrl();
  }

  @override
  void didUpdateWidget(AvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarPath != widget.avatarPath) {
      _loadAvatarUrl();
    }
  }

  Future<void> _loadAvatarUrl() async {
    if (widget.avatarPath == null || widget.avatarPath!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = false;
        _signedUrl = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Check if it's a private storage path that needs a signed URL
      if (AvatarService.isPrivateStoragePath(widget.avatarPath)) {
        final signedUrl = await AvatarService.getAvatarSignedUrl(
          avatarPath: widget.avatarPath!,
          expiryInSeconds: 3600, // 1 hour
        );

        if (mounted) {
          setState(() {
            _signedUrl = signedUrl;
            _isLoading = false;
            _hasError = signedUrl == null;
          });
        }
      } else {
        // It's a public URL or asset path, use directly
        if (mounted) {
          setState(() {
            _signedUrl = widget.avatarPath;
            _isLoading = false;
            _hasError = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading avatar URL: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _signedUrl = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: const CircularProgressIndicator(),
          );
    }

    if (_hasError || _signedUrl == null) {
      return widget.errorWidget ?? _buildDefaultAvatar();
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ??
          BorderRadius.circular(widget.size != null ? widget.size! / 2 : 0),
      child: CachedNetworkImage(
        imageUrl: _signedUrl!,
        width: widget.size,
        height: widget.size,
        fit: widget.fit,
        placeholder: (context, url) =>
            widget.placeholder ??
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: const CircularProgressIndicator(),
            ),
        errorWidget: (context, url, error) =>
            widget.errorWidget ?? _buildDefaultAvatar(),
        fadeInDuration: const Duration(milliseconds: 300),
        memCacheWidth: widget.size?.toInt(),
        memCacheHeight: widget.size?.toInt(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: const Color(0xFF00CC58),
        borderRadius: widget.borderRadius ??
            BorderRadius.circular(widget.size != null ? widget.size! / 2 : 0),
      ),
      child: Icon(
        Icons.person,
        size: widget.size != null ? widget.size! * 0.6 : 24,
        color: Colors.white,
      ),
    );
  }
}

/// Factory constructor for profile avatars with optimal settings
class ProfileAvatar extends StatelessWidget {
  final String? avatarPath;
  final double? size;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ProfileAvatar({
    super.key,
    this.avatarPath,
    this.size,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AvatarImage(
      avatarPath: avatarPath,
      size: size,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fit: BoxFit.cover,
    );
  }
}
