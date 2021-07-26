import 'package:flutter/material.dart';

import '../keyboard_avoider.dart';

/// A widget that will ensure that its child remains above the keyboard when focused.
/// [keyboardPadding] is the padding maintained between the bottom of the [child] widget and the top of the keyboard.
/// [focusNode] is a `FocusNode` that is used to determine when the padding avoider needs to add padding.
class KeyboardPaddingBox extends StatefulWidget {
  const KeyboardPaddingBox(
      {Key? key,
      double? keyboardOffset,
      this.paddingFactor = 1,
      required List<FocusNode> focusNodes,
      Duration? duration,
      Curve? animationCurve})
      : this._fns = focusNodes,
        this.keyboardPadding = keyboardOffset ?? 0,
        this.duration = duration ?? const Duration(milliseconds: 200),
        this.animationCurve = animationCurve ?? Curves.decelerate,
        super(key: key);

  final List<FocusNode> _fns;
  final double keyboardPadding;
  final double paddingFactor;
  final Curve animationCurve;
  final Duration duration;

  @override
  _KeyboardPaddingBoxState createState() => _KeyboardPaddingBoxState();
}

class _KeyboardPaddingBoxState extends State<KeyboardPaddingBox>
    with WidgetsBindingObserver {
  // widgets binding observer has didChangeMetrics which is called when viewport resizes

  @override
  void initState() {
    super.initState();
    // allows for watching for changes in the widgets like did change metrics
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  double paddingAmount = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        padding:
            EdgeInsets.fromLTRB(0, 0, 0, paddingAmount * widget.paddingFactor),
        duration: widget.duration,
        curve: widget.animationCurve,
        child: Container());
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      for (var fn in widget._fns) {
        if (fn.hasFocus) {
          checkResize(fn.context?.findRenderObject() as RenderBox);
        } else {
          // if still active, they don't move it as if use selects textfield above the
          // kb then it will suddenly drop down under the kb
          if (!Keyboard.of(context).isActive) {
            setState(() {
              paddingAmount = 0;
            });
          }
        }
      }
    });
  }

  void checkResize(RenderBox? renderBox) {
    if (renderBox == null) {
      print('render box was null');
      return;
    }

    // top left of widget from top left of screen
    var offset = renderBox.localToGlobal(Offset.zero);
    // add box's height to offset to get bottom of widget. Also add keyboard padding
    var widgetBottom =
        offset.dy + renderBox.size.height + widget.keyboardPadding;

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenInsets = mediaQuery.viewInsets;

    // screenInsets.bottom is the distance from bottom of screen to top of keyboard inset
    // translate to y coord:
    final keyboardTop = screenSize.height - screenInsets.bottom;

    // if keyboardTop less than widgetBottom then keyboardTop higher up and overlapping

    if (keyboardTop < widgetBottom) {
      var overlap = widgetBottom - keyboardTop;
      setState(() {
        paddingAmount = overlap * widget.paddingFactor;
      });
    }
  }
}
