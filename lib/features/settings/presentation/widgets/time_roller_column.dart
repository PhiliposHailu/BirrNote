import 'package:flutter/material.dart';

class TimeRollerColumn extends StatefulWidget {
  final String label;
  final int maxCount;
  final int initialItem;
  final ValueChanged<int> onChanged;
  final bool is12Hour; // NEW!

  const TimeRollerColumn({
    super.key,
    required this.label,
    required this.maxCount,
    required this.initialItem,
    required this.onChanged,
    this.is12Hour = false, // Default is 24h mode
  });

  @override
  State<TimeRollerColumn> createState() => _TimeRollerColumnState();
}

class _TimeRollerColumnState extends State<TimeRollerColumn> {
  bool _isEditing = false;
  late final FixedExtentScrollController _scrollController;
  late final TextEditingController _textController;
  late int _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.initialItem;
    _scrollController = FixedExtentScrollController(initialItem: _currentItem);
    
    // FIXED: If 12h mode, display 01-12 instead of index 0-11
    final initialDisplay = widget.is12Hour ? _currentItem + 1 : _currentItem;
    _textController = TextEditingController(text: initialDisplay.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _submit(String val) {
    var value = int.tryParse(val);
    if (value != null) {
      if (widget.is12Hour) {
        value = value - 1; // Convert typed 1-12 to index 0-11
      }
      setState(() {
        _isEditing = false;
        if (value! >= 0 && value < widget.maxCount) {
          _currentItem = value;
          _scrollController.jumpToItem(value);
          widget.onChanged(value);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
          height: 150,
          child: _isEditing
              ? Center(
                  child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    maxLength: 2,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                    onSubmitted: _submit,
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    setState(() {}); 
                    return false;
                  },
                  child: ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() => _currentItem = index);
                      widget.onChanged(index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.maxCount,
                      builder: (context, index) {
                        double offset = _currentItem.toDouble();
                        if (_scrollController.hasClients) {
                          offset = _scrollController.offset / 50.0;
                        }
                        final double distance = (index - offset).abs();
                        final double opacity = (1.0 - (distance * 0.7)).clamp(0.3, 1.0);
                        final double fontSize = (32.0 - (distance * 8.0)).clamp(22.0, 32.0);
                        final isSelected = index == _currentItem;

                        // FIXED: Render 1-12 instead of 0-11 in the wheel!
                        final displayValue = widget.is12Hour ? index + 1 : index;

                        return GestureDetector(
                          onTap: () {
                            if (isSelected) {
                              setState(() {
                                _isEditing = true;
                                _textController.text = displayValue.toString().padLeft(2, '0');
                              });
                            }
                          },
                          child: Center(
                            child: Text(
                              displayValue.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: Colors.white.withOpacity(opacity),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}