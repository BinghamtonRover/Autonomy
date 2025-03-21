import "package:behavior_tree/behavior_tree.dart";

class TimeLimit extends BaseNode {
  DateTime? _start;

  final BaseNode child;
  final Duration timeout;
  final NodeStatus statusAfterTimeout;

  TimeLimit({
    required this.child,
    required this.timeout,
    this.statusAfterTimeout = NodeStatus.failure,
  });

  @override
  void tick() {
    _start ??= DateTime.now();

    if (DateTime.now().difference(_start!) >= timeout) {
      status = statusAfterTimeout;
      return;
    }

    child.tick();
    status = child.status;
  }

  @override
  void reset() {
    _start = null;
    child.reset();

    super.reset();
  }
}

class DelayedNode extends BaseNode {
  DateTime? _start;

  final Duration delay;

  DelayedNode(this.delay);

  @override
  void tick() {
    _start ??= DateTime.now();

    if (DateTime.now().difference(_start!) >= delay) {
      status = NodeStatus.success;
    } else {
      status = NodeStatus.running;
    }
  }

  @override
  void reset() {
    _start = null;
    super.reset();
  }
}

class ConditionalNode extends BaseNode {
  final bool Function() condition;

  final BaseNode? onTrue;
  final BaseNode? onFalse;

  bool? _initialConditionState;

  ConditionalNode({required this.condition, this.onTrue, this.onFalse})
    : assert(
        onTrue != null || onFalse != null,
        "onTrue() or onFalse() must be non-null, if there is no intended child node, use a Condition() instead!",
      );

  @override
  void tick() {
    _initialConditionState ??= condition();

    if (_initialConditionState!) {
      if (onTrue != null) {
        onTrue!.tick();
        status = onTrue!.status;
      } else if (onFalse != null) {
        status = NodeStatus.success;
      }
    } else {
      if (onFalse != null) {
        onFalse!.tick();
        status = onFalse!.status;
      } else if (onTrue != null) {
        status = NodeStatus.success;
      }
    }
  }

  @override
  void reset() {
    _initialConditionState = null;
    onTrue?.reset();
    onFalse?.reset();
    super.reset();
  }
}

class SuppliedNode extends BaseNode {
  BaseNode? _child;

  final BaseNode Function() supplier;
  final Object? Function()? key;

  Object? _lastKey;

  SuppliedNode(this.supplier, {this.key}) : _lastKey = key?.call();

  @override
  void tick() {
    if (_child == null) {
      _child = supplier();
    } else if (key != null) {
      final currentKey = key!.call();
      if (currentKey != _lastKey) {
        _child?.reset();
        _child = supplier();
      }
      _lastKey = currentKey;
    }

    _child!.tick();
    status = _child!.status;
  }

  @override
  void reset() {
    _child?.reset();
    _child = null;
    super.reset();
  }
}

extension BehaviorDecorators on BaseNode {
  BaseNode get inverted => Inverter(this);

  BaseNode withTimeout(
    Duration timeout, {
    NodeStatus statusAfterTimeout = NodeStatus.failure,
  }) => TimeLimit(
    child: this,
    timeout: timeout,
    statusAfterTimeout: statusAfterTimeout,
  );
}
