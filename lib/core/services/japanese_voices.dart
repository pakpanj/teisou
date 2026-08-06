/// Picks a male and a female ja-JP voice out of whatever the device's TTS
/// engine offers.
///
/// **Why this is not just a name-substring check.** The previous version
/// looked for "male"/"female" inside the voice name. Google's Japanese
/// voices — which is what almost every Android device actually has — are
/// named `ja-jp-x-jab-local`, `ja-jp-x-htm-network`, and so on. Nothing in
/// those names says anything about gender, so the check found nothing,
/// both voices stayed null, and every line in the app fell back to the one
/// default voice. That is precisely the "everything sounds like the same
/// woman" the module was supposed to avoid.
///
/// So the families are named here, from **measurement rather than
/// assumption**: the same sentence was synthesised with each voice on a
/// Moto G52J and its fundamental frequency measured.
///
/// | voice | median F0 | 10th percentile |
/// |---|---|---|
/// | `ja-jp-x-htm` | 304 Hz | 214 Hz |
/// | `ja-jp-x-jab` | 270 Hz | 214 Hz |
/// | `ja-jp-x-jad` | 180 Hz | 117 Hz |
/// | `ja-jp-x-jac` | 163 Hz | 109 Hz |
///
/// The 10th percentile is the telling column: jac and jad reach down into
/// the male chest register, and jab and htm never go below ~214 Hz. The
/// search covered 55-450 Hz, so this is not an octave-detection artefact.
/// `ja-JP-language`, the legacy default, synthesised a **byte-identical**
/// file to `ja-jp-x-jab-local` — it is jab under another name, which is
/// why the app used to sound uniformly female.
///
/// Kept as a pure function over a voice list so all of this is testable
/// without a device or an audio engine.
library;

import '../../data/models/kaiwa_line.dart';

/// One installed TTS voice, reduced to what matters here.
typedef VoiceMap = Map<String, String>;

/// Google's ja-JP voice families, measured, **in preference order** —
/// deepest male and highest female first, so the two chosen voices are
/// the pair furthest apart and a learner can tell them apart on a phone
/// speaker. Only the three-letter family code is matched, so both the
/// `-local` and `-network` variant of each is recognised.
const _googleMaleFamilies = ['jac', 'jad'];
const _googleFemaleFamilies = ['htm', 'jab'];

/// Chooses one voice per gender, or null where the device has nothing
/// suitable — a normal outcome on an engine with a single Japanese voice,
/// and the caller falls back to a pitch shift.
class JapaneseVoices {
  const JapaneseVoices({this.male, this.female});

  final VoiceMap? male;
  final VoiceMap? female;

  bool get hasBoth => male != null && female != null;

  /// [voices] is the raw list from `FlutterTts.getVoices`, already
  /// filtered to Japanese locales.
  factory JapaneseVoices.from(List<VoiceMap> voices) {
    VoiceMap? pick(bool Function(String name) matches) {
      // Offline first: a `-network` voice needs a live connection for
      // every single line, and this app is used on the bus.
      final hits = voices.where((v) => matches(_nameOf(v))).toList();
      if (hits.isEmpty) return null;
      return hits.firstWhere(
        (v) => !_nameOf(v).contains('network'),
        orElse: () => hits.first,
      );
    }

    // Family by family, in the order declared above rather than in
    // whatever order the device happens to list its voices — otherwise
    // the pair that gets chosen is an accident of the engine's ordering,
    // and on the test device that meant the shallower of the two male
    // voices won.
    VoiceMap? pickFamily(List<String> families) {
      for (final family in families) {
        final hit = pick((n) => n.contains('-$family-'));
        if (hit != null) return hit;
      }
      return null;
    }

    // Google's families first: they are the common case, and the only
    // ones whose pitch was actually measured.
    var male = pickFamily(_googleMaleFamilies);
    var female = pickFamily(_googleFemaleFamilies);

    // Some OEM and third-party engines do spell it out. Only consulted
    // when the Google families are absent, so a device with both never
    // gets a worse answer from a vaguer signal.
    male ??= pick((n) => n.contains('male') && !n.contains('female'));
    female ??= pick((n) => n.contains('female'));

    // Two voices that came back the same are no better than one: return
    // neither and let the caller shift pitch instead, which at least
    // sounds different.
    if (male != null && female != null && _nameOf(male) == _nameOf(female)) {
      return const JapaneseVoices();
    }
    return JapaneseVoices(male: male, female: female);
  }

  static String _nameOf(VoiceMap v) => (v['name'] ?? '').toLowerCase();
}

/// Which voice to speak a line in when the content does not say.
///
/// Most Kaiwa speakers are roles — "Dokter", "Guru", "Petugas Bank",
/// "Teman" — and **the dataset deliberately leaves those genderless**,
/// because a doctor can be anyone and writing one into the content would
/// be a claim the content has no business making. But something still has
/// to come out of the speaker.
///
/// So the voice is derived from a stable key instead. The same speaker in
/// the same dialogue always sounds the same, a learner hears a genuine mix
/// across the app rather than one woman playing every part, and no claim
/// about the role is recorded anywhere. Two different doctors in two
/// different dialogues sounding different is correct — they are two
/// different doctors.
KaiwaGender voiceForSpeaker({
  required String dialogueId,
  required String speaker,
  KaiwaGender? authored,
}) {
  if (authored != null) return authored;
  // FNV-1a over the pair. Any stable hash would do; what matters is that
  // it does not change between runs, which `Object.hash` does not
  // guarantee across sessions.
  var hash = 0x811c9dc5;
  for (final code in '$dialogueId/$speaker'.codeUnits) {
    hash = (hash ^ code) * 0x01000193 & 0xffffffff;
  }
  return hash.isEven ? KaiwaGender.female : KaiwaGender.male;
}
