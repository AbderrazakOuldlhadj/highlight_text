import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:highlight_texto/controller.dart';

const sharedText = 'Flutter is Google’s UI toolkit for building beautiful, '
    'natively compiled applications for mobile, web, and desktop from a single codebase.';

const sharedTextStyle = TextStyle(
  fontSize: 30,
  height: 1.4,
);

void main() {
  runApp(
    MaterialApp(
      home: Material(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: HomePage(),
        ),
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextSelection _currentSelection = const TextSelection.collapsed(offset: 0);

  void _onSelectionChange(TextSelection textSelection) {
    /*setState(() {
      _currentSelection = textSelection;
    });*/
  }

  @override
  Widget build(BuildContext context) {
    final selectedText = _currentSelection.textInside(sharedText);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableTextGoal(
            text: sharedText,
            style: sharedTextStyle,
            onSelectionChange: _onSelectionChange,
          ),
          /*const SizedBox(height: 48),
          Text(
            selectedText.isNotEmpty ? selectedText : 'No Text Selected',
            style: sharedTextStyle.copyWith(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),*/
        ],
      ),
    );
  }
}

class SelectableTextGoal extends StatefulWidget {
  SelectableTextGoal({
    Key? key,
    this.text = '',
    this.initialSelection,
    required this.style,
    this.selectionColor = Colors.lightBlueAccent,
    this.caretColor = Colors.black,
    this.caretWidth = 1,
    this.changeCursor = true,
    this.allowSelection = true,
    this.paintTextBoxes = false,
    this.textBoxesColor = Colors.grey,
    required this.onSelectionChange,
  }) : super(key: key);

  final String text;
  final TextSelection? initialSelection;
  final TextStyle style;
  Color selectionColor;
  final Color caretColor;
  final double caretWidth;
  final bool changeCursor;
  final bool allowSelection;
  bool paintTextBoxes = false;
  final Color textBoxesColor;
  final void Function(TextSelection) onSelectionChange;

  @override
  _SelectableTextGoalState createState() => _SelectableTextGoalState();
}

class _SelectableTextGoalState extends State<SelectableTextGoal> {
  var highController = Get.put(HighlightController());
  final _textKey = GlobalKey();

  final _textBoxRects = <Rect>[];

  final _selectionRects = <Rect>[];
  final _selectionRects2 = <Rect>[];
  TextSelection? _textSelection;
  int? _selectionBaseOffset;

  Rect? _caretRect;

  bool showColors = false;

  List<MaterialColor> colors = [
    Colors.green,
    Colors.red,
    Colors.pink,
  ];

  //MouseCursor _cursor = SystemMouseCursors.basic;

  @override
  void initState() {
    super.initState();
    _textSelection =
        widget.initialSelection ?? const TextSelection.collapsed(offset: -1);
    _scheduleTextLayoutUpdate();
  }

  @override
  void didUpdateWidget(SelectableTextGoal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _textBoxRects.clear();
      _selectionRects.clear();
      _textSelection = const TextSelection.collapsed(offset: -1);
      _caretRect = null;

      _scheduleTextLayoutUpdate();
    }
  }

  RenderParagraph? get _renderParagraph =>
      _textKey.currentContext?.findRenderObject() as RenderParagraph;

  void _scheduleTextLayoutUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _updateVisibleTextBoxes();
      _updateSelectionDisplay();
    });
  }

  void _onDragStart(DragStartDetails details) {
    highController.color.value = Colors.lightBlue;
    setState(() {
      _selectionBaseOffset =
          _getTextPositionAtOffset(details.localPosition).offset;
      _onUserSelectionChange(
        TextSelection.collapsed(offset: _selectionBaseOffset!),
      );
    });
    print("start");
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      final selectionExtentOffset =
          _getTextPositionAtOffset(details.localPosition).offset;
      final textSelection = TextSelection(
        baseOffset: _selectionBaseOffset!,
        extentOffset: selectionExtentOffset,
      );

      _onUserSelectionChange(textSelection);
    });
    print('update');
  }

  void _onDragEnd(DragEndDetails details) {
   /* setState(() {
      //_selectionBaseOffset = null;
      //widget.paintTextBoxes = !widget.paintTextBoxes;
    });*/
    print("end");
  }

  void _onDragCancel() {
    setState(() {
      _selectionBaseOffset = null;
      _onUserSelectionChange(const TextSelection.collapsed(offset: 0));
    });
    print("cancel");
  }

  /*void _onMouseMove(PointerEvent event) {
    if (!widget.changeCursor) {
      return;
    }

    if (event is PointerHoverEvent) {
      setState(() {
        _cursor = _isOffsetOverText(event.localPosition)
            ? SystemMouseCursors.text
            : SystemMouseCursors.basic;
      });
    }
  }*/

  void _onUserSelectionChange(TextSelection textSelection) {
    _textSelection = textSelection;
    _updateSelectionDisplay();
    widget.onSelectionChange.call(textSelection);
  }

  void _updateSelectionDisplay() {
    setState(() {
      final selectionRects = _computeSelectionRects(_textSelection!);
      final selectionRects2 = _computeSelectionRects(_textSelection!);
      _selectionRects
        ..clear()
        ..addAll(selectionRects);
      _selectionRects2
        ..clear()
        ..addAll(selectionRects2);
      _caretRect = _textSelection != null
          ? _computeCursorRectForTextOffset(_textSelection!.extentOffset)
          : null;
    });
  }

  void _updateVisibleTextBoxes() {
    setState(() {
      _textBoxRects
        ..clear()
        ..addAll(_computeAllTextBoxRects());
    });
  }

  Rect _computeCursorRectForTextOffset(int offset) {
    if (offset < 0) {
      return Rect.zero;
    }
    if (_renderParagraph == null) {
      return Rect.zero;
    }

    final caretOffset = _renderParagraph!.getOffsetForCaret(
      TextPosition(offset: offset),
      Rect.zero,
    );
    final caretHeight = _renderParagraph!.getFullHeightForCaret(
      TextPosition(offset: offset),
    );
    return Rect.fromLTWH(
      caretOffset.dx - (widget.caretWidth / 2),
      caretOffset.dy,
      widget.caretWidth,
      caretHeight!,
    );
  }

  TextPosition _getTextPositionAtOffset(Offset localOffset) {
    final myBox = context.findRenderObject();
    final textOffset =
        _renderParagraph!.globalToLocal(localOffset, ancestor: myBox);
    return _renderParagraph!.getPositionForOffset(textOffset);
  }

  bool _isOffsetOverText(Offset localOffset) {
    final rects = _computeAllTextBoxRects();
    for (final rect in rects) {
      if (rect.contains(localOffset)) {
        return true;
      }
    }
    return false;
  }

  List<Rect> _computeAllTextBoxRects() {
    if (_textKey.currentContext == null) {
      return const [];
    }

    if (_renderParagraph == null) {
      return const [];
    }

    return _computeSelectionRects(
      TextSelection(
        baseOffset: 0,
        extentOffset: widget.text.length,
      ),
    );
  }

  List<Rect> _computeSelectionRects(TextSelection selection) {
    if (selection == null) {
      return [];
    }
    if (_renderParagraph == null) {
      return [];
    }

    final textBoxes = _renderParagraph!.getBoxesForSelection(selection);
    return textBoxes.map((box) => box.toRect()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(
        ()=> CustomPaint(
            painter: _SelectionPainter(
              color: highController.color.value,
              rects: _selectionRects,
            ),
          ),
        ),

        GestureDetector(
          onPanStart: widget.allowSelection ? _onDragStart : null,
          onPanUpdate: widget.allowSelection ? _onDragUpdate : null,
          onPanEnd: widget.allowSelection ? _onDragEnd : null,
          onPanCancel: widget.allowSelection ? _onDragCancel : null,
          behavior: HitTestBehavior.translucent,
          child: Text(
            widget.text,
            key: _textKey,
            style: widget.style,
          ),
        ),
        CustomPaint(
          painter: _SelectionPainter(
            color: widget.caretColor,
            rects: _caretRect != null ? [_caretRect!] : const [],
          ),
        ),
        if (_selectionRects.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: colors
                  .map(
                    (e) => GestureDetector(
                      onTap: () {
                        highController.color.value = e;
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        height: 25,
                        width: 25,
                        color: e,
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
      ],
    );
  }
}

class _SelectionPainter extends CustomPainter {
  _SelectionPainter({
    required Color color,
    required List<Rect> rects,
    bool fill = true,
  })  : _color = color,
        _rects = rects,
        _fill = fill,
        _paint = Paint()..color = color;

  final Color _color;
  final bool _fill;
  final List<Rect> _rects;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    _paint.style = _fill ? PaintingStyle.fill : PaintingStyle.stroke;
    for (final rect in _rects) {
      canvas.drawRect(rect, _paint);
    }
  }

  @override
  bool shouldRepaint(_SelectionPainter other) {
    return true;
  }
}
