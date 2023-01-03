import 'package:flutter/widgets.dart';

import 'map_sheet_controller.dart';
import 'map_sheet_simulations.dart';
import 'modified_scroll_view.dart';

class MapSheet extends StatefulWidget {
  const MapSheet({
    Key? key,
    this.child,
    this.slivers = const [],
    this.onScrollEnd,
    this.scrollController,
    this.sheetController,
    this.backgroundBuilder,
    required this.simulationBuilder,
  }) : super(key: key);

  final Widget? child;
  final WidgetBuilder? backgroundBuilder;
  final List<Widget> slivers;
  final ScrollController? scrollController;
  final MapSheetController? sheetController;
  final void Function(ScrollEndNotification notification)? onScrollEnd;
  final Simulation? Function(
    ScrollMetrics position,
    double velocity,
    SpringDescription spring,
    Tolerance tolerance,
  ) simulationBuilder;

  @override
  State<MapSheet> createState() => MapSheetState();
}

class MapSheetState extends State<MapSheet> {
  double? _animatingDestination;
  Simulation? _animatingSimulation;
  StateSetter? backgroundStateSetter;
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.scrollController ?? ScrollController();
    widget.sheetController?.state = this;
    if (widget.backgroundBuilder != null) {
      _controller.addListener(() {
        backgroundStateSetter?.call(() {});
      });
    }
  }

  @override
  void dispose() {
    widget.sheetController?.state = null;
    super.dispose();
  }

  void animateToPosition({double? target, Simulation? simulation}) {
    _animatingDestination = target;
    _animatingSimulation = simulation;
    if (target != null || simulation != null) {
      _controller.jumpTo(_controller.offset);
    }
  }

  Simulation? simulationBuilder(ScrollMetrics position, double velocity,
      SpringDescription spring, Tolerance tolerance) {
    final scrollPosition = position.pixels;
    if (_animatingDestination != null) {
      if (scrollPosition == _animatingDestination) {
        return null;
      }
      if (_animatingSimulation != null) {
        return _animatingSimulation!;
      } else {
        return SpringScrollSimulation(
          spring: spring,
          position: scrollPosition,
          velocity: velocity,
          tolerance: tolerance,
          destination: _animatingDestination!,
        );
      }
    }
    if (_animatingSimulation != null) {
      return _animatingSimulation!;
    }
    return widget.simulationBuilder.call(position, velocity, spring, tolerance);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, size) {
      return Stack(
        children: [
          if (widget.child != null)
            RepaintBoundary(
              child: widget.child!,
            ),
          if (widget.backgroundBuilder != null)
            StatefulBuilder(
              builder: (context, state) {
                backgroundStateSetter = state;
                double top = 0;
                if (_controller.hasClients) {
                  if (_controller.offset <= 0) {
                    top = -_controller.offset;
                  }
                }
                if (top > size.maxHeight) {
                  top = size.maxHeight;
                }
                return Positioned(
                  top: top,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: widget.backgroundBuilder!.call(context),
                );
              },
            ),
          SizedBox.expand(
            child: NotificationListener(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  widget.onScrollEnd?.call(notification);
                }
                return false;
              },
              child: Listener(
                onPointerDown: (detail) {
                  _animatingDestination = null;
                  _animatingSimulation = null;
                },
                child: ModifiedCustomScrollView(
                  controller: _controller,
                  physics: MapSheetBouncingScrollPhysics(
                      parent: const AlwaysScrollableScrollPhysics(),
                      simulationBuilder: simulationBuilder),
                  slivers: widget.slivers,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
