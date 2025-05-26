import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Utility class for converting SVG assets to BitmapDescriptor for Google Maps markers
class SvgToBitmap {
  /// Convert SVG asset to BitmapDescriptor by rendering SvgPicture widget
  ///
  /// [assetPath] - Path to the SVG asset (e.g., 'assets/svg/bus.svg')
  /// [size] - Desired size of the icon (default: 60x60)
  static Future<BitmapDescriptor> fromSvgAsset(
    String assetPath, {
    Size size = const Size(60.0, 60.0),
  }) async {
    try {
      // Create SVG widget
      final Widget svgWidget = SvgPicture.asset(
        assetPath,
        width: size.width,
        height: size.height,
        fit: BoxFit.contain,
      );

      // Create a container to hold the SVG with specific size
      final Widget container = Container(
        width: size.width,
        height: size.height,
        color: Colors.transparent,
        child: svgWidget,
      );

      // Convert widget to image
      final ui.Image image = await _widgetToImage(container, size);

      // Convert image to bytes
      final ByteData? bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw Exception('Failed to convert image to bytes');
      }

      // Create BitmapDescriptor from bytes
      final BitmapDescriptor bitmapDescriptor = BitmapDescriptor.fromBytes(
        bytes.buffer.asUint8List(),
      );

      // Dispose image
      image.dispose();

      return bitmapDescriptor;
    } catch (e) {
      debugPrint('SvgToBitmap: Error converting SVG to BitmapDescriptor: $e');
      rethrow;
    }
  }

  /// Helper method to convert widget to image
  static Future<ui.Image> _widgetToImage(Widget widget, Size size) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
    final RenderView renderView = RenderView(
      view: ui.PlatformDispatcher.instance.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration.fromView(
        ui.PlatformDispatcher.instance.views.first,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: widget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final double devicePixelRatio =
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final ui.Image image =
        await repaintBoundary.toImage(pixelRatio: devicePixelRatio);
    return image;
  }

  /// Create a bus icon BitmapDescriptor specifically for driver markers
  static Future<BitmapDescriptor> busIcon({
    Size size = const Size(50.0, 50.0),
  }) async {
    return fromSvgAsset('assets/svg/bus.svg', size: size);
  }

  /// Create a cached version of the bus icon to avoid repeated conversions
  static BitmapDescriptor? _cachedBusIcon;

  /// Get cached bus icon or create new one if not cached
  static Future<BitmapDescriptor> getCachedBusIcon({
    Size size = const Size(50.0, 50.0),
  }) async {
    _cachedBusIcon ??= await busIcon(size: size);
    return _cachedBusIcon!;
  }

  /// Clear cached icons (useful for memory management)
  static void clearCache() {
    _cachedBusIcon = null;
  }

  /// Convert any SVG asset to BitmapDescriptor with color tinting
  ///
  /// [assetPath] - Path to the SVG asset
  /// [color] - Optional color to tint the SVG
  /// [size] - Desired size of the icon
  static Future<BitmapDescriptor> fromSvgAssetWithColor(
    String assetPath, {
    Color? color,
    Size size = const Size(60.0, 60.0),
  }) async {
    try {
      // Create SVG widget with color filter
      Widget svgWidget = SvgPicture.asset(
        assetPath,
        width: size.width,
        height: size.height,
        fit: BoxFit.contain,
      );

      // Apply color filter if specified
      if (color != null) {
        svgWidget = ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: svgWidget,
        );
      }

      // Create a container to hold the SVG with specific size
      final Widget container = Container(
        width: size.width,
        height: size.height,
        color: Colors.transparent,
        child: svgWidget,
      );

      // Convert widget to image
      final ui.Image image = await _widgetToImage(container, size);

      // Convert image to bytes
      final ByteData? bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw Exception('Failed to convert image to bytes');
      }

      // Create BitmapDescriptor from bytes
      final BitmapDescriptor bitmapDescriptor = BitmapDescriptor.fromBytes(
        bytes.buffer.asUint8List(),
      );

      // Dispose image
      image.dispose();

      return bitmapDescriptor;
    } catch (e) {
      debugPrint(
          'SvgToBitmap: Error converting SVG with color to BitmapDescriptor: $e');
      rethrow;
    }
  }
}
