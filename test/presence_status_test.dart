import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/presence_status.dart';

void main() {
  group('PresenceStatus.fromSnapshotValue', () {
    test('null value (node never written) is offline', () {
      final status = PresenceStatus.fromSnapshotValue(null);
      expect(status.isOnline, isFalse);
      expect(status.lastChanged, isNull);
    });

    test('state: online parses as online with a lastChanged timestamp', () {
      final status = PresenceStatus.fromSnapshotValue({
        'state': 'online',
        'lastChanged': 1700000000000,
      });
      expect(status.isOnline, isTrue);
      expect(
        status.lastChanged,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
    });

    test('state: offline parses as offline', () {
      final status = PresenceStatus.fromSnapshotValue({
        'state': 'offline',
        'lastChanged': 1700000000000,
      });
      expect(status.isOnline, isFalse);
    });

    test('handles the loosely-typed Map the plugin actually returns, not '
        'just Map<String, dynamic>', () {
      final Map raw = <Object?, Object?>{
        'state': 'online',
        'lastChanged': 1700000000000,
      };
      final status = PresenceStatus.fromSnapshotValue(raw);
      expect(status.isOnline, isTrue);
    });

    test('missing lastChanged leaves it null instead of throwing', () {
      final status = PresenceStatus.fromSnapshotValue({'state': 'online'});
      expect(status.isOnline, isTrue);
      expect(status.lastChanged, isNull);
    });

    test('an unrecognized state value is treated as offline, not a crash',
        () {
      final status = PresenceStatus.fromSnapshotValue({
        'state': 'something-unexpected',
        'lastChanged': 1700000000000,
      });
      expect(status.isOnline, isFalse);
    });
  });

  test('PresenceStatus.offline() is the same shape as a null snapshot', () {
    final fromFactory = PresenceStatus.offline();
    final fromNull = PresenceStatus.fromSnapshotValue(null);
    expect(fromFactory.isOnline, fromNull.isOnline);
    expect(fromFactory.lastChanged, fromNull.lastChanged);
  });
}
