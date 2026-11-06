import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/rentals/domain/qr_ticket.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12);

  QrTicket ticket({
    bool used = false,
    Duration validFor = const Duration(days: 1),
  }) {
    return QrTicket(
      token: 'QR-123',
      signature: 'abc',
      phase: QrPhase.pickup,
      issuedAt: now,
      expiresAt: now.add(validFor),
      used: used,
    );
  }

  group('vigencia y un solo uso del QR (HU-17)', () {
    test('un QR sin usar y dentro de vigencia es válido', () {
      expect(ticket().stateAt(now), QrState.valid);
      expect(ticket().isValidAt(now), isTrue);
    });

    test('un QR usado deja de ser válido', () {
      final t = ticket(used: true);
      expect(t.stateAt(now), QrState.used);
      expect(t.isValidAt(now), isFalse);
    });

    test('un QR vencido deja de ser válido', () {
      final t = ticket();
      final afterExpiry = now.add(const Duration(days: 2));
      expect(t.stateAt(afterExpiry), QrState.expired);
      expect(t.isValidAt(afterExpiry), isFalse);
    });

    test('marcar como usado es irreversible en la vigencia', () {
      final t = ticket().copyWith(used: true);
      expect(t.stateAt(now), QrState.used);
    });

    test('el payload incluye token, fase y firma', () {
      final t = ticket();
      expect(t.payload, contains('QR-123'));
      expect(t.payload, contains(QrPhase.pickup.name));
      expect(t.payload, contains('abc'));
    });
  });
}
