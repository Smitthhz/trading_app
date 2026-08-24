import 'package:flutter/widgets.dart';

import 'app/trading_app.dart';
import 'app/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const TradingApp());
}
