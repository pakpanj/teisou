import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// One consistent "you got something" SnackBar for every purchase-success
/// moment in the app — coin Top Up, and a coin-spent cosmetic/skin — so a
/// learner sees the same modest, polished acknowledgement regardless of
/// which of those flows they just completed, instead of each screen
/// inventing its own plain text bar.
///
/// **Deliberately a function, not a widget.** A `SnackBar` is shown
/// through `ScaffoldMessenger`, not built into the widget tree, so there
/// is nothing here to mount, keep alive, or dispose — the same shape
/// every other one-off `ScaffoldMessenger.showSnackBar` call in this app
/// already uses, just with shared styling instead of a bare
/// `SnackBar(content: Text(...))`.
///
/// **Deliberately does not call `hideCurrentSnackBar()` first.** That
/// was tried and reverted: it silently erases whatever the *previous*
/// call showed the moment a second one fires, which is exactly the
/// wrong thing when two calls landing back to back is itself a bug (see
/// `ShopTab._onOutcome`'s own guard, and
/// `test/purchase_success_ux_test.dart`, which caught this the hard way
/// — with `hideCurrentSnackBar()` in place, a real duplicate-listener
/// regression silently vanished from view instead of surfacing as the
/// visible double-SnackBar it actually is). One purchase should only
/// ever produce one call here in the first place; each call site is
/// responsible for that, not this helper.
void showPurchaseSuccessSnackBar(
  BuildContext context, {
  required String message,
  IconData icon = Icons.check_circle,
}) {
  final palette = context.palette;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: palette.successGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: palette.successGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: palette.textNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
