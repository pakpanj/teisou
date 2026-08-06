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

/// **`jab` before `htm`, deliberately the opposite of "highest first".**
/// htm is the shrillest voice the engine has at 304 Hz, and using it for
/// every woman in the app is what "cempreng banget" was describing. jab
/// at 270 Hz is the cleaner of the two and now carries both female
/// registers, with htm kept only as the fallback if jab is missing.
const _googleFemaleFamilies = ['jab', 'htm'];

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

/// How old the speaker sounds.
///
/// Two women in this app are not the same woman: a classmate and a school
/// teacher should not share one voice, and the engine offers no second
/// female voice worth using (see [_googleFemaleFamilies] — the other one
/// is the shrill one this split exists to stop using). So the register is
/// carried by pitch on top of the chosen voice.
enum VoiceRegister {
  /// A friend, a classmate, someone your own age.
  peer,

  /// A teacher, a doctor, a boss, a parent — anyone the learner would
  /// address with a title. Heavier and slower-sounding.
  mature,
}

/// Roles that should sound like an adult with some standing, rather than
/// like the learner's friend.
///
/// Matched on the **bare role**, after any Pak/Bu has been stripped, so
/// "Bu Guru" and "Guru" land in the same place. Shop and counter staff are
/// deliberately absent: a cashier or a waiter is as likely to be twenty as
/// fifty, and making every service worker sound middle-aged would be its
/// own kind of wrong.
const _matureRoles = <String>{
  'Guru', 'Dokter', 'Dosen', 'Perawat', 'Instruktur', 'Pelatih',
  'Atasan', 'Senior', 'Rekan Bisnis', 'Klien',
  'Orang Tua', 'Ibu', 'Ayah', 'Kakek', 'Nenek', 'Tetangga',
  'Apoteker', 'Resepsionis', 'Pemilik Toko',
};

/// Strips a Pak/Bu so the role underneath can be recognised.
String _bareRole(String speaker) {
  for (final title in const ['Pak ', 'Bu ', 'Ibu ', 'Kak ']) {
    if (speaker.startsWith(title)) return speaker.substring(title.length);
  }
  return speaker;
}

/// Whether this speaker should sound older than the learner.
///
/// A Pak/Bu title is taken as sufficient on its own — an Indonesian
/// speaker does not call a peer "Pak" — which also means a named elder
/// like "Pak Tanaka" is caught without having to list every name.
VoiceRegister registerForSpeaker(String speaker) {
  final titled = speaker.startsWith('Pak ') ||
      speaker.startsWith('Bu ') ||
      speaker.startsWith('Ibu ');
  if (titled) return VoiceRegister.mature;
  return _matureRoles.contains(_bareRole(speaker))
      ? VoiceRegister.mature
      : VoiceRegister.peer;
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
