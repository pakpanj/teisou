import 'package:flutter/material.dart';

/// The app's single `Navigator`, reachable without a `BuildContext` — the
/// one thing a notification tap genuinely needs and can't otherwise have.
/// Tapping a chat/clan-message push can happen from a cold start (no
/// widget tree exists yet at all) or from deep in the background (no
/// context anywhere near the screen the tap should open), so `FcmService`
/// pushes routes through `rootNavigatorKey.currentState` instead of
/// threading a context through the whole notification pipeline.
final rootNavigatorKey = GlobalKey<NavigatorState>();
