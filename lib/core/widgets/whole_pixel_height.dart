import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Lays [child] out and rounds its height up to a whole logical pixel.
///
/// For rows of fixed-height lists (`SliverPrototypeExtentList`,
/// `ReorderableListView.prototypeItem`): a row's offset is its height times
/// its index, and a fractional height (screen scaling, e.g. 66.67) drifts
/// past Flutter's layout tolerance around row 5,000.
class WholePixelHeight extends SingleChildRenderObjectWidget {
  const WholePixelHeight({super.key, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWholePixelHeight();
}

class _RenderWholePixelHeight extends RenderProxyBox {
  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(
      Size(child.size.width, child.size.height.ceilToDouble()),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width).ceilToDouble();

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width).ceilToDouble();
}
