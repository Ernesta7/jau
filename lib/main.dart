import 'package:flutter/material.dart';

import 'package:jau/app.dart';
import 'package:jau/state_widget.dart';

// - StateWidget incl. state data
//    - RecipesApp
//        - All other widgets which are able to access the data
void main() {
  StateWidget stateWidget = new StateWidget(child:new RecipesApp());
  runApp(stateWidget);
}
