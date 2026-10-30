import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionNotifier extends ChangeNotifier {
  void notifySessionExpired() {
    notifyListeners();
  }
}

final sessionNotifierProvider = Provider<SessionNotifier>((ref) {
  return SessionNotifier();
});
