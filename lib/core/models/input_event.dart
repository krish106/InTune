enum InputAction {
  move,
  leftClick,
  rightClick,
  doubleClick,
  dragStart,
  dragMove,
  dragEnd,
  scroll,
  keyPress,
}

class InputEvent {
  final InputAction action;
  final double x;  // Normalized 0.0 to 1.0
  final double y;  // Normalized 0.0 to 1.0
  final int? scrollDelta;
  final String? key;
  
  InputEvent({
    required this.action,
    required this.x,
    required this.y,
    this.scrollDelta,
    this.key,
  });
  
  Map<String, dynamic> toPayload() => {
    'action': action.name,
    'x': x,
    'y': y,
    'scrollDelta': scrollDelta,
    'key': key,
  };
  
  static InputEvent fromPayload(Map<String, dynamic> payload) {
    return InputEvent(
      action: InputAction.values.firstWhere((e) => e.name == payload['action']),
      x: (payload['x'] as num).toDouble(),
      y: (payload['y'] as num).toDouble(),
      scrollDelta: payload['scrollDelta'] as int?,
      key: payload['key'] as String?,
    );
  }
  
  @override
  String toString() {
    return 'InputEvent(action: $action, x: ${x.toStringAsFixed(3)}, y: ${y.toStringAsFixed(3)})';
  }
}
