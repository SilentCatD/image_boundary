import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

class ImageBoundaryController extends ChangeNotifier {
  Future<Uint8List?> capture({
    double pixelsRatio = 1.0,
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) {
    final resultCompleter = Completer<Uint8List?>();
    _notifierWithCompleter(resultCompleter, pixelsRatio, format);
    return resultCompleter.future;
  }

  Completer<Uint8List?>? _completer;
  ui.ImageByteFormat? _format;
  double? _pixelsRatio;

  void _notifierWithCompleter(
    Completer<Uint8List?> completer,
    double pixelsRatio,
    ui.ImageByteFormat format,
  ) {
    _completer = completer;
    _format = format;
    _pixelsRatio = pixelsRatio;
    notifyListeners();
  }
}

class ImageBoundaryResolver extends StatefulWidget {
  const ImageBoundaryResolver({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;

  static _ImageBoundaryResolverState _of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ImageResolverScope>();
    return scope!.state;
  }

  @override
  State<ImageBoundaryResolver> createState() => _ImageBoundaryResolverState();
}

class _ImageBoundaryResolverState extends State<ImageBoundaryResolver> {
  final _repaintKey = GlobalKey();

  void resolve(Completer<Uint8List?> completer, Rect smallerBoundRect,
      ui.ImageByteFormat format, double pixelsRatio) async {
    final renderObject = _repaintKey.currentContext?.findRenderObject()
        as RenderFractionalImageRepaintBoundary?;
    if (renderObject == null) {
      completer.complete(null);
      return;
    }
    final size = renderObject.size;
    final offset = renderObject.localToGlobal(Offset.zero);
    final biggerBoundRect = offset & size;
    final left = smallerBoundRect.left - biggerBoundRect.left;
    final top = smallerBoundRect.top - biggerBoundRect.top;
    final right = left + smallerBoundRect.width;
    final bottom = top + smallerBoundRect.height;
    assert(left >= 0);
    assert(top >= 0);
    assert(right >= 0);
    assert(bottom >= 0);
    final resolvedRect = Rect.fromLTRB(left, top, right, bottom);

    final image = await renderObject.toImageWithBound(
        rect: resolvedRect, pixelRatio: pixelsRatio);
    final byteData = await image.toByteData(format: format);
    final pngBytes = byteData?.buffer.asUint8List();
    completer.complete(pngBytes);
  }

  @override
  Widget build(BuildContext context) {
    return _ImageResolverScope(
      state: this,
      child: FractionalImageRepaintBoundary(
        key: _repaintKey,
        child: widget.child,
      ),
    );
  }
}

class _ImageResolverScope extends InheritedWidget {
  final _ImageBoundaryResolverState state;

  const _ImageResolverScope({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

class ImageBoundary extends StatefulWidget {
  const ImageBoundary({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);
  final ImageBoundaryController controller;
  final Widget child;

  @override
  State<ImageBoundary> createState() => _ImageBoundaryState();
}

class _ImageBoundaryState extends State<ImageBoundary> {
  final _childKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleCaptureRequest);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleCaptureRequest);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ImageBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleCaptureRequest);
      widget.controller.addListener(_handleCaptureRequest);
    }
  }

  void _handleCaptureRequest() {
    final completer = widget.controller._completer;
    final format = widget.controller._format;
    final ratio = widget.controller._pixelsRatio;
    if (completer == null || format == null || ratio == null) return;
    final boundaryResolver = ImageBoundaryResolver._of(context);
    final renderObject =
        _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderObject == null) return;
    final size = renderObject.size;
    final offset = renderObject.localToGlobal(Offset.zero);
    final rect = offset & size;
    boundaryResolver.resolve(completer, rect, format, ratio);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _childKey,
      child: widget.child,
    );
  }
}

class FractionalImageRepaintBoundary extends RepaintBoundary {
  const FractionalImageRepaintBoundary({
    super.key,
    super.child,
  });

  @override
  RenderFractionalImageRepaintBoundary createRenderObject(
      BuildContext context) {
    return RenderFractionalImageRepaintBoundary();
  }
}

class RenderFractionalImageRepaintBoundary extends RenderRepaintBoundary {
  RenderFractionalImageRepaintBoundary({
    super.child,
  });

  Future<ui.Image> toImageWithBound(
      {required Rect rect, double pixelRatio = 1.0}) {
    assert(!debugNeedsPaint);
    final OffsetLayer offsetLayer = layer! as OffsetLayer;
    return offsetLayer.toImage(rect, pixelRatio: pixelRatio);
  }
}
