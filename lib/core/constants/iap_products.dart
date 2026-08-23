/// Everything this app sells, by store product id.
///
/// **These ids have to exist in the store before any of this works.**
/// Nothing here creates them: they are typed into Google Play Console
/// (Monetise → Products) and App Store Connect by hand, and a
/// `queryProductDetails` for an id that was never created comes back in
/// `notFoundIDs` rather than failing loudly. That is why
/// [IapService.load] reports what was not found instead of quietly
/// showing an empty shop.
///
/// Ids are deliberately plain and permanent. A store product id can
/// never be renamed or reused once created, and a learner who bought
/// `skin_cloud_white` must still own it in five years, so they read as
/// what they are rather than carrying a version or a price in the name.
class IapProducts {
  /// **The master switch for everything that takes money.**
  ///
  /// `false` kept every line of the purchase flow compiled, tested and
  /// ready without ever reaching a store — enforced inside [IapService]
  /// rather than by hiding buttons, so no call site could bypass it by
  /// accident: with this off, `load` contacted nothing, `buy` opened no
  /// sheet, and `restore` asked for nothing.
  ///
  /// **On as of 2026-08-23** — `teisou_premium_monthly` (Rp 19.000/bulan)
  /// exists in Play Console with an active base plan, the Firebase
  /// Functions service account has Android Publisher access, and
  /// `PLAY_VERIFICATION_ENABLED=true` is deployed (see
  /// `functions/iap.js`). `firestore.rules` already refused client
  /// writes to `subscription`/`entitlements` before this flipped, so no
  /// rules change was needed to turn this on specifically.
  ///
  /// **Still only real on a Play-installed build.** A debug APK
  /// installed over USB reports every product as not found even with
  /// this `true` — Play only serves purchases to a build installed
  /// *from* Play, signed with the same key. Verifying the buy button
  /// needs a release build through Internal Testing, not a local
  /// install. iOS stays unverifiable regardless of this flag —
  /// `functions/iap.js` refuses every non-Android platform on purpose
  /// until Apple's App Store Server API is wired in.
  static const bool purchasesEnabled = true;

  /// The one subscription: opens every premium module at once. Sold as a
  /// subscription rather than a one-off because the content keeps
  /// growing — N3-N1 kanji, Bunpou's upper levels, Kaiwa, Choukai — and
  /// a single lifetime price would have to be set for content that does
  /// not exist yet.
  static const premiumMonthly = 'teisou_premium_monthly';

  /// Card skins, sold individually. Ids match [CardSkinPreset.id] with a
  /// prefix, so the mapping needs no table — see [skinIdFor].
  static const skinPrefix = 'skin_';

  static String productIdForSkin(String skinId) => '$skinPrefix$skinId';

  /// The skin a product id refers to, or null if it is not a skin
  /// product. The inverse of [productIdForSkin], kept beside it so the
  /// two cannot drift.
  static String? skinIdFor(String productId) =>
      productId.startsWith(skinPrefix)
          ? productId.substring(skinPrefix.length)
          : null;

  /// Every id to ask the store about on startup. Built from the skin
  /// list rather than typed twice, so a skin added to the shop is asked
  /// for automatically — and shows up in `notFoundIDs` until somebody
  /// creates it in the console, which is the reminder to do so.
  static Set<String> all(Iterable<String> paidSkinIds) => {
        premiumMonthly,
        for (final id in paidSkinIds) productIdForSkin(id),
      };
}
