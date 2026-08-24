import 'package:cloud_functions/cloud_functions.dart';

/// One kind of cosmetic a coin purchase can target — mirrors the
/// `kind` string `functions/spend_coins.js` expects. Avatar/frame/cover
/// write to `xp.unlocked{Kind}Ids`; [skin] is the odd one out and writes
/// to `entitlements.skins` instead — the same array a real-money card
/// skin purchase already lands in, so `ownedSkinsProvider` can't tell
/// the two apart. See `spend_coins.js`'s own doc comment for why.
enum CoinSpendKind { avatar, frame, cover, skin }

/// Buying an avatar/frame/cover permanently with coins.
///
/// **Why this is a callable, not a Firestore write.** `coins` is frozen
/// against every client write, and the unlock id has to land atomically
/// with the deduction or a modified client could grant itself the
/// unlock without ever paying — see `functions/spend_coins.js`'s own
/// doc comment for the full reasoning. This class is deliberately thin:
/// it has no state of its own, unlike `PremiumPurchaseFlow`/
/// `CoinPurchaseFlow`, because there is no store purchase sheet or
/// outcome stream in this flow — it's one request, one response.
class CoinSpendService {
  CoinSpendService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Spends coins on [id] of [kind]. Returns true once owned — including
  /// when it was already owned, so a caller doesn't need to special-case
  /// "already bought this" as a different outcome from "just bought it".
  /// Throws [CoinSpendException] with a reason the caller can show, on
  /// every other failure (not enough coins, not signed in, network).
  Future<bool> buy(CoinSpendKind kind, String id) async {
    try {
      final result = await _functions.httpsCallable('spendCoins').call({
        'kind': kind.name,
        'id': id,
      });
      final data = result.data;
      return data is Map && data['granted'] == true;
    } on FirebaseFunctionsException catch (e) {
      throw CoinSpendException(
        notEnoughCoins: e.code == 'failed-precondition',
      );
    } catch (_) {
      throw const CoinSpendException(notEnoughCoins: false);
    }
  }
}

/// What went wrong buying a cosmetic with coins. [notEnoughCoins]
/// distinguishes the one failure a learner can actually fix (top up
/// more) from everything else (network, not signed in), which reads the
/// same to them either way but shouldn't be worded as "you need more
/// coins" when that isn't actually true.
class CoinSpendException implements Exception {
  const CoinSpendException({required this.notEnoughCoins});

  final bool notEnoughCoins;
}
