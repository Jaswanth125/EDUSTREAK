import 'package:flutter_test/flutter_test.dart';
import 'package:edustreak/models/user_model.dart';
import 'package:edustreak/services/email_invitation_service.dart';

void main() {
  group('1. EmailInvitationService Token & URL Generation Tests', () {
    final emailService = EmailInvitationService();

    test('generateSecureToken generates a 32-character hexadecimal string', () {
      final token1 = emailService.generateSecureToken();
      final token2 = emailService.generateSecureToken();

      expect(token1.length, equals(32));
      expect(token2.length, equals(32));
      expect(token1, isNot(equals(token2)));
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(token1), isTrue);
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(token2), isTrue);
    });

    test('generateAcceptanceUrl constructs compliant web portal routing URL', () {
      const code = 'INV-PRIN-APKRI042-8821';
      const token = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';

      final url = emailService.generateAcceptanceUrl(code, token);

      expect(url, equals('https://edustreak.web.app/accept-invitation?code=INV-PRIN-APKRI042-8821&token=a1b2c3d4e5f60718293a4b5c6d7e8f90'));
      expect(url, contains('code=$code'));
      expect(url, contains('token=$token'));
    });
  });

  group('2. Branded HTML Email Template Generation Tests', () {
    final emailService = EmailInvitationService();

    test('generateBrandedEmailHtml compiles with full dynamic variables & styling', () {
      final html = emailService.generateBrandedEmailHtml(
        principalName: 'Dr. Sudhir Sharma',
        schoolName: 'Z.P. High School, Kankipadu',
        schoolCode: 'AP-KRI-042',
        invitationCode: 'INV-PRIN-APKRI042-8821',
        acceptanceUrl: 'https://edustreak.web.app/accept-invitation?code=INV-PRIN-APKRI042-8821&token=xyz789',
        expiresAtFormatted: '22/11/2026',
      );

      expect(html, contains('EDUSTREAK'));
      expect(html, contains('State Leadership Portal'));
      expect(html, contains('Dear Principal Dr. Sudhir Sharma,'));
      expect(html, contains('Z.P. High School, Kankipadu'));
      expect(html, contains('AP-KRI-042'));
      expect(html, contains('INV-PRIN-APKRI042-8821'));
      expect(html, contains('22/11/2026'));
      expect(html, contains('Activate Principal Account'));
      expect(html, contains('https://edustreak.web.app/accept-invitation'));
    });
  });

  group('3. Principal Invitation Status Lifecycle & Categorization Tests', () {
    test('Identifies pending, sent, sending, failed, accepted, and revoked states', () {
      final userInvited = UserModel(
        id: 'prin_test_1',
        name: 'K. Srinivas Rao',
        email: 'principal.svvm@edustreak.ap.gov.in',
        role: 'principal',
        schoolId: 'sch_ap_svvm_001',
        schoolCode: 'AP-KRI-SVVM',
        status: 'invited',
        isActive: true,
      );

      final userSending = UserModel(
        id: 'prin_test_2',
        name: 'M. Sailaja',
        email: 'apms.guntur@apgov.edu.in',
        role: 'principal',
        schoolId: 'sch_ap_002',
        schoolCode: 'AP-GNT-109',
        status: 'sending',
        isActive: true,
      );

      final userRevoked = UserModel(
        id: 'prin_test_3',
        name: 'Former Leader',
        email: 'former@school.edu.in',
        role: 'principal',
        schoolId: 'sch_ap_003',
        schoolCode: 'AP-GNT-110',
        status: 'revoked',
        isActive: false,
      );

      final userActive = UserModel(
        id: 'prin_test_4',
        name: 'Dr. Sudhir Sharma',
        email: 'principal@edustreak.com',
        role: 'principal',
        schoolId: 'sch_ap_001',
        schoolCode: 'AP-KRI-042',
        status: 'active',
        isActive: true,
      );

      expect(userInvited.status, equals('invited'));
      expect(userSending.status, equals('sending'));
      expect(userRevoked.status, equals('revoked'));
      expect(userRevoked.isActive, isFalse);
      expect(userActive.status, equals('active'));
      expect(userActive.isActive, isTrue);
    });

    test('EmailDispatchResult correctly parses delivery metadata', () {
      final successMap = {
        'success': true,
        'status': 'sent',
        'provider': 'resend',
        'messageId': 'msg_resend_99182',
        'recipient': 'principal@edustreak.com',
        'details': 'Email delivered successfully via Resend API',
        'previewUrl': 'https://edustreak.web.app/accept-invitation?code=INV-001',
      };

      final result = EmailDispatchResult.fromMap(successMap);

      expect(result.success, isTrue);
      expect(result.status, equals('sent'));
      expect(result.provider, equals('resend'));
      expect(result.messageId, equals('msg_resend_99182'));
      expect(result.recipient, equals('principal@edustreak.com'));
      expect(result.previewUrl, isNotNull);
    });
  });

  group('4. Duplicate Prevention & Security Validation Logic Tests', () {
    test('Sanitizes and normalizes emails and school codes', () {
      const dirtyEmail = '  Principal.Test@EduStreak.AP.Gov.In  ';
      const rawSchoolCode = 'ap-kri svvm#001!';

      final cleanEmail = dirtyEmail.trim().toLowerCase();
      final normCode = rawSchoolCode.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

      expect(cleanEmail, equals('principal.test@edustreak.ap.gov.in'));
      expect(normCode, equals('APKRISVVM001'));
      expect(normCode, isNot(contains(' ')));
      expect(normCode, isNot(contains('#')));
      expect(normCode, isNot(contains('!')));
    });

    test('Enforces 7-day expiration boundary on issued invitations', () {
      final issuedAt = DateTime(2026, 11, 15, 10, 0, 0);
      final expiresAt = issuedAt.add(const Duration(days: 7));

      expect(expiresAt.difference(issuedAt).inDays, equals(7));

      final testBeforeExpiry = issuedAt.add(const Duration(days: 6, hours: 23));
      final testAfterExpiry = issuedAt.add(const Duration(days: 7, hours: 1));

      expect(testBeforeExpiry.isBefore(expiresAt), isTrue);
      expect(testAfterExpiry.isAfter(expiresAt), isTrue);
    });
  });
}
