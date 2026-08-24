import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/card_skins.dart';
import '../../core/constants/iap_products.dart';
import '../../core/providers.dart';
import '../../core/services/iap_service.dart';
import '../../core/theme/app_palette.dart';

/// The shop — now a till, not just a window.
///
/// **What is sold here can never be earned, and what is earned can never
/// be sold.** That line is the reason the families exist at all (see
/// [CardSkinSource]), and it is why this screen says so out loud rather
/// than leaving a buyer to wonder whether they paid for something a
/// patient player gets free.
///
/// **Prices come from the store, never from the app.** A hardcoded
/// "Rp 15.000" is wrong in every other country, wrong after any price
/// change, and wrong the moment a sale runs; `ProductDetails.price`
/// arrives already localised and already current. A skin whose product
/// has not been created in the console yet has no price to show, so its
/// button is disabled rather than showing a number nobody can pay.
class ShopTab extends ConsumerStatefulWidget {
  const ShopTab({super.key});

  @override
  ConsumerState<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends ConsumerState<ShopTab> {
  StreamSubscription<IapOutcome>? _outcomeSub;
  bool _loading = true;
  String? _buying;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final iap = ref.read(iapServiceProvider);
    _outcomeSub ??= iap.outcomes.listen(_onOutcome);
    await iap.load(
      IapProducts.all(
        CardSkinPresets.ofSource(CardSkinSource.paid).map((skin) => skin.id),
      ),
    );
    if (mounted) setState(() => _loading = false);
  }

  void _onOutcome(IapOutcome outcome) {
    if (!mounted) return;
    final s = ref.read(appStringsProvider);
    setState(() => _buying = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (outcome) {
          IapOutcome.delivered => s.purchaseDelivered,
          IapOutcome.cancelled => s.purchaseCancelled,
          IapOutcome.unavailable => s.storeUnavailable,
          IapOutcome.failed => s.purchaseFailed,
        }),
      ),
    );
  }

  Future<void> _buy(CardSkinPreset skin) async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    // Nothing is sold to nobody: the purchase is bound to the buyer's
    // account, and the server refuses a token without one.
    if (uid == null) {
      _onOutcome(IapOutcome.failed);
      return;
    }
    setState(() => _buying = skin.id);
    final opened = await ref
        .read(iapServiceProvider)
        .buy(IapProducts.productIdForSkin(skin.id), uid: uid);
    // `false` means the sheet never opened, so no outcome will arrive —
    // without this the button would spin for ever.
    if (!opened && mounted) setState(() => _buying = null);
  }

  @override
  void dispose() {
    _outcomeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final iap = ref.read(iapServiceProvider);
    final owned = ref.watch(ownedSkinsProvider).valueOrNull ?? const <String>{};
    final paid = CardSkinPresets.ofSource(CardSkinSource.paid).toList();
    // Owned-vs-not split, same as the Avatar/Bingkai/Sampul tabs — see
    // `AvatarPickerBody`'s doc comment above its own `isLocked` for the
    // reasoning behind grouping by ownership rather than a flat list.
    final ownedSkins = paid.where((skin) => owned.contains(skin.id)).toList();
    final notOwnedSkins = paid.where((skin) => !owned.contains(skin.id)).toList();
    // With purchases switched off the store is never asked anything, so
    // `isAvailable` is false — but saying "the store is not available on
    // this device" would blame the phone for a decision made here. The
    // shop stays browsable either way; only the buying is off.
    const selling = IapProducts.purchasesEnabled;
    final storeSilent =
        !selling || (!_loading && (!iap.isAvailable || iap.missingProducts.isNotEmpty));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (storeSilent) ...[
          _Notice(
            text: (!selling || iap.isAvailable)
                ? s.shopNotOpenYet
                : s.storeUnavailable,
            palette: palette,
          ),
          const SizedBox(height: 18),
        ],
        Text(
          s.shopSkinsHeading,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: palette.textNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.shopSkinsSubtitle,
          style: TextStyle(
            fontSize: 12,
            color: palette.textNavy.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 14),
        if (ownedSkins.isNotEmpty) ...[
          _SectionLabel(s.ownedSectionTitle, palette: palette),
          const SizedBox(height: 8),
          for (final skin in ownedSkins) ...[
            _ShopRow(
              skin: skin,
              label: skin.labelFor(s.language),
              price: iap.productFor(IapProducts.productIdForSkin(skin.id))?.price,
              owned: true,
              busy: false,
              onBuy: () => _buy(skin),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 6),
        ],
        if (notOwnedSkins.isNotEmpty) ...[
          _SectionLabel(s.notOwnedSectionTitle, palette: palette),
          const SizedBox(height: 8),
          for (final skin in notOwnedSkins) ...[
            _ShopRow(
              skin: skin,
              label: skin.labelFor(s.language),
              price: iap.productFor(IapProducts.productIdForSkin(skin.id))?.price,
              owned: false,
              busy: _buying == skin.id,
              onBuy: () => _buy(skin),
            ),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 8),
        // Required by both stores, and the only way back for someone who
        // paid and then changed phone: the purchase lives on their store
        // account, not on this device. Hidden while nothing is on sale,
        // because there is nothing to restore and a button that silently
        // does nothing is worse than no button.
        if (selling)
          Center(
            child: TextButton(
              onPressed: () => ref.read(iapServiceProvider).restore(),
              child: Text(s.purchaseRestore),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.palette});

  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.tertiaryAmberCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: palette.textNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: palette.textNavy),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Sudah Dimiliki"/"Belum Dimiliki" above each half of the skin list —
/// same wording and reasoning as the Avatar/Bingkai/Sampul tabs' owned-vs-
/// not split, kept as a small local widget rather than importing across
/// features (`avatar_picker_sheet.dart`'s `PickerSectionTitle` lives under
/// `features/profile/`, this screen under `features/battle/`).
class _SectionLabel extends StatelessWidget {
  final String text;
  final AppPalette palette;

  const _SectionLabel(this.text, {required this.palette});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontWeight: FontWeight.bold, color: palette.textNavy),
    );
  }
}

class _ShopRow extends ConsumerWidget {
  const _ShopRow({
    required this.skin,
    required this.label,
    required this.price,
    required this.owned,
    required this.busy,
    required this.onBuy,
  });

  final CardSkinPreset skin;
  final String label;

  /// The store's own localised price, or null when the store has never
  /// heard of this product.
  final String? price;
  final bool owned;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 79,
            child: CardSkinBack(
              skin: skin,
              borderRadius: 10,
              showCrest: false,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.textNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.shopSkinRowNote,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (owned)
            // Nothing to sell twice. Everything here is non-consumable,
            // so a button on an owned skin would take money for
            // something already owned.
            Icon(Icons.check_circle, color: palette.secondaryBlue)
          else if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            FilledButton(
              // Disabled rather than hidden when there is no price yet:
              // the shelf should still look like a shelf.
              onPressed: price == null ? null : onBuy,
              child: Text(price ?? s.shopBuySoon),
            ),
        ],
      ),
    );
  }
}
