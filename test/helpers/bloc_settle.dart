import 'package:flutter_test/flutter_test.dart';

/// Lets bloc event handlers and their futures run before asserting state.
Future<void> settleBloc([int milliseconds = 30]) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));
