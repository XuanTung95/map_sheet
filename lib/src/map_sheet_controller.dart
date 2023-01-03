import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'map_sheet.dart';


class MapSheetController {

  MapSheetState? _state;
  MapSheetState? get state => _state;
  set state(MapSheetState? value) {
    _state = value;
  }

  void animateToPosition({double? target, Simulation? simulation}) {
    _state?.animateToPosition(target: target, simulation: simulation);
  }
}