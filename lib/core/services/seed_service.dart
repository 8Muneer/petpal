import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';

class SeedService {
  final FirebaseFirestore _firestore;

  SeedService({required FirebaseFirestore firestore}) : _firestore = firestore;

  /// One-off migration for legacy data.
  ///
  /// Before the two-sided completion flow, the review prompt opened as soon as
  /// a booking was `accepted`, so some bookings have a review while still
  /// sitting in `accepted`. Under the new model the review is gated on
  /// `completed`, so those bookings would show "awaiting completion" instead of
  /// the review they already have. This moves any `accepted` booking that
  /// already has a review to `completed`.
  ///
  /// Best-effort per document: a booking the current user can't update (not
  /// theirs, or its service date hasn't passed) is skipped, not fatal. Returns
  /// the number of bookings migrated.
  Future<int> migrateAcceptedReviewedToCompleted() async {
    final snap = await _firestore
        .collection('booking_requests')
        .where('status', isEqualTo: 'accepted')
        .get();

    var migrated = 0;
    for (final doc in snap.docs) {
      try {
        // Reviews are stored with the booking id as the document id.
        final review =
            await _firestore.collection('reviews').doc(doc.id).get();
        if (!review.exists) continue;
        await doc.reference.update({'status': 'completed'});
        migrated++;
      } catch (_) {
        // Skip documents the current user isn't permitted to update.
      }
    }
    return migrated;
  }

  // ─── CURATED HEBREW DATA (all male — names and grammar) ───

  static const List<String> _hebrewFirstNames = [
    'איתי', 'נועם', 'דניאל', 'אורי', 'איתן', 'יונתן', 'גיא', 'יהונתן', 'אריאל', 'משה',
    'עומר', 'רועי', 'אלון', 'ניר', 'יובל', 'אסף', 'שחר', 'עידן', 'רון', 'בן',
    'תומר', 'אבישי', 'ליאור', 'דור', 'נדב', 'אוהד', 'מתן', 'יאיר', 'עמית', 'זיו',
  ];

  static const List<String> _hebrewLastNames = [
    'כהן', 'לוי', 'מזרחי', 'פרץ', 'ביטון', 'דהן', 'אברהם', 'פרידמן', 'מלכה', 'אזולאי',
  ];

  static const List<String> _areas = [
    'תל אביב', 'ירושלים', 'חיפה', 'ראשון לציון', 'פתח תקווה',
    'אשדוד', 'נתניה', 'באר שבע', 'רמת גן', 'חולון',
  ];

  static const List<String> _petNames = [
    'לואי', 'סימבה', 'בל', 'לוסי', 'מקס', 'צ׳ארלי', 'רוקי', 'לולה', 'מיילו', 'ג׳וי',
  ];

  static const List<String> _dogBreeds = [
    'לברדור', 'גולדן רטריבר', 'פודל', 'האסקי סיביר', 'בורדר קולי',
    'יורקשייר טרייר', 'ביגל', 'רועה גרמני', 'שיצו', 'בולדוג צרפתי',
  ];

  static const List<String> _catBreeds = [
    'פרסי', 'בריטי קצר שיער', 'מיין קון', 'סיאמי', 'בנגל',
    'ראגדול', 'אבסיני', 'סקוטיש פולד', 'ספינקס', 'חתול בית',
  ];

  static const List<String> _petColors = [
    'חום', 'שחור', 'לבן', 'אפור', 'זהבי', 'כתום', 'פסים', 'שחור-לבן',
  ];

  static const List<String> _providerPhotos = [
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
  ];

  static const List<String> _petPhotos = [
    'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=400',
    'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=400',
    'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400',
    'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=400',
    'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?w=400',
  ];

  /// 12 distinct points of interest — 4 parks, 4 vets (2 of them 24h
  /// emergency), 4 stores — spread across different cities, each with its own
  /// image, address, rating, opening hours and services. Matches the
  /// `POI` entity (lib/features/explore/domain/entities/poi_model.dart):
  /// type is the raw enum name ('park'|'vet'|'store'); openingHours keys are
  /// 'sun'..'sat' (lib/features/explore/presentation/widgets/poi_card.dart).
  static const List<Map<String, dynamic>> _poiProfiles = [
    {
      'name': 'גן מאיר (גינת כלבים)',
      'type': 'park',
      'latitude': 32.0747, 'longitude': 34.7733,
      'rating': 4.8, 'reviewCount': 120,
      'imageUrl': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&q=80&w=800',
      'address': 'המלך ג׳ורג׳, תל אביב',
      'tags': ['מרכזי', 'חולי', 'מוצל'],
      'description': 'גינת כלבים מרכזית עם דשא ואזור מוצלל, פתוחה לציבור כל היום.',
      'open24h': true,
      'services': ['מתקני אילוף', 'ברזיית מים', 'שקיות איסוף'],
    },
    {
      'name': 'גינת כלבים פארק הירקון',
      'type': 'park',
      'latitude': 32.0988, 'longitude': 34.8094,
      'rating': 4.9, 'reviewCount': 350,
      'imageUrl': 'https://images.unsplash.com/photo-1601758124510-52d02ddb7cbd?auto=format&fit=crop&q=80&w=800',
      'address': 'גני יהושע, תל אביב',
      'tags': ['ענק', 'דשא', 'על המים'],
      'description': 'שטח דשא נרחב על גדות הירקון, פופולרי לטיולים ומשחק חופשי.',
      'open24h': true,
      'services': ['שטח גדור', 'ברזיית מים'],
    },
    {
      'name': 'גן הפיסגה (גינת כלבים)',
      'type': 'park',
      'latitude': 32.7940, 'longitude': 34.9896,
      'rating': 4.6, 'reviewCount': 64,
      'imageUrl': 'https://images.unsplash.com/photo-1517849845537-4d257902454a?auto=format&fit=crop&q=80&w=800',
      'address': 'שדרות הנשיא, חיפה',
      'tags': ['נוף', 'שטח גדול'],
      'description': 'גינת כלבים עם נוף פנורמי למפרץ חיפה, שטח פתוח גדול.',
      'open24h': true,
      'services': ['שטח גדור', 'תאורה בלילה'],
    },
    {
      'name': 'פארק קנדה (גינת כלבים)',
      'type': 'park',
      'latitude': 31.7683, 'longitude': 35.2137,
      'rating': 4.5, 'reviewCount': 47,
      'imageUrl': 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&q=80&w=800',
      'address': 'גבעת מסואה, ירושלים',
      'tags': ['משפחתי', 'שטחי דשא'],
      'description': 'פארק משפחתי עם אזור מסודר לכלבים ומדשאות פתוחות.',
      'open24h': true,
      'services': ['ברזיית מים', 'שקיות איסוף'],
    },
    {
      'name': 'בית חולים וטרינרי תורן (חירום)',
      'type': 'vet',
      'latitude': 32.0853, 'longitude': 34.7818,
      'isEmergency': true,
      'rating': 4.7, 'reviewCount': 85,
      'imageUrl': 'https://images.unsplash.com/photo-1628033033580-0a14917a02c8?auto=format&fit=crop&q=80&w=800',
      'address': 'אבן גבירול, תל אביב',
      'phoneNumber': '03-1234567',
      'tags': ['24/7', 'מומחים', 'כירורגיה'],
      'description': 'בית חולים וטרינרי עם חדר מיון פעיל סביב השעון לכל סוגי החיות.',
      'website': 'https://vet-emergency-ta.demo.petpal.com',
      'email': 'info@vet-emergency-ta.demo.petpal.com',
      'open24h': true,
      'services': ['חירום', 'ניתוחים', 'אשפוז', 'הדמיה'],
    },
    {
      'name': 'מרפאה וטרינרית ד"ר דוליטל',
      'type': 'vet',
      'latitude': 32.0625, 'longitude': 34.7711,
      'rating': 4.5, 'reviewCount': 42,
      'imageUrl': 'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?auto=format&fit=crop&q=80&w=800',
      'address': 'רוטשילד, תל אביב',
      'phoneNumber': '03-7654321',
      'tags': ['חיסונים', 'יחס אישי'],
      'description': 'מרפאה שכונתית לטיפול שגרתי, חיסונים ובדיקות תקופתיות.',
      'website': 'https://dr-dolittle.demo.petpal.com',
      'email': 'clinic@dr-dolittle.demo.petpal.com',
      'open24h': false,
      'openingHours': {
        'sun': '09:00-18:00', 'mon': '09:00-18:00', 'tue': '09:00-18:00',
        'wed': '09:00-18:00', 'thu': '09:00-18:00', 'fri': '09:00-13:00',
      },
      'services': ['חיסונים', 'בדיקות שגרה', 'שבבים'],
    },
    {
      'name': 'מרפאה וטרינרית רמת גן',
      'type': 'vet',
      'latitude': 32.0684, 'longitude': 34.8248,
      'rating': 4.4, 'reviewCount': 29,
      'imageUrl': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&q=80&w=800',
      'address': 'ביאליק, רמת גן',
      'phoneNumber': '03-5559876',
      'tags': ['טיפול שיניים', 'הדמיה'],
      'description': 'מרפאה וטרינרית עם מעבדה פנימית וטיפולי שיניים לחיות מחמד.',
      'open24h': false,
      'openingHours': {
        'sun': '08:30-17:00', 'mon': '08:30-17:00', 'tue': '08:30-17:00',
        'wed': '08:30-17:00', 'thu': '08:30-19:00',
      },
      'services': ['טיפול שיניים', 'מעבדה', 'הדמיה'],
    },
    {
      'name': 'מרכז וטרינרי באר שבע (חירום)',
      'type': 'vet',
      'latitude': 31.2530, 'longitude': 34.7915,
      'isEmergency': true,
      'rating': 4.6, 'reviewCount': 38,
      'imageUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=800',
      'address': 'רגר, באר שבע',
      'phoneNumber': '08-6661234',
      'tags': ['24/7', 'חירום', 'אזור הדרום'],
      'description': 'מרכז חירום וטרינרי יחיד באזור הדרום, פתוח כל שעות היממה.',
      'open24h': true,
      'services': ['חירום', 'ניתוחים', 'אשפוז'],
    },
    {
      'name': 'פט-ביי (חנות חיות)',
      'type': 'store',
      'latitude': 32.0722, 'longitude': 34.7822,
      'rating': 4.6, 'reviewCount': 156,
      'imageUrl': 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&q=80&w=800',
      'address': 'דיזנגוף, תל אביב',
      'phoneNumber': '03-9876543',
      'tags': ['משלוחים', 'מזון רפואי'],
      'description': 'חנות חיות עם מבחר מזון רפואי, אביזרים ושירות משלוחים עד הבית.',
      'website': 'https://pet-bay.demo.petpal.com',
      'open24h': false,
      'openingHours': {
        'sun': '09:00-20:00', 'mon': '09:00-20:00', 'tue': '09:00-20:00',
        'wed': '09:00-20:00', 'thu': '09:00-21:00', 'fri': '09:00-14:00',
      },
      'services': ['משלוחים', 'מזון רפואי', 'הטמנת שבב'],
    },
    {
      'name': 'אנימל-שופ',
      'type': 'store',
      'latitude': 32.0455, 'longitude': 34.7555,
      'rating': 4.4, 'reviewCount': 98,
      'imageUrl': 'https://images.unsplash.com/photo-1591768793355-74d7ca7fb9c4?auto=format&fit=crop&q=80&w=800',
      'address': 'יפו, תל אביב',
      'phoneNumber': '03-1112233',
      'tags': ['זול', 'ציוד מקצועי'],
      'description': 'חנות ציוד מקצועי במחירים נוחים — רצועות, מיטות, צעצועים ועוד.',
      'open24h': false,
      'openingHours': {
        'sun': '10:00-19:00', 'mon': '10:00-19:00', 'tue': '10:00-19:00',
        'wed': '10:00-19:00', 'thu': '10:00-19:00',
      },
      'services': ['ציוד', 'הטמנת שבב'],
    },
    {
      'name': 'חיות מחמד פתח תקווה',
      'type': 'store',
      'latitude': 32.0840, 'longitude': 34.8878,
      'rating': 4.3, 'reviewCount': 31,
      'imageUrl': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=800',
      'address': 'רוטשילד, פתח תקווה',
      'phoneNumber': '03-9234567',
      'tags': ['מזון', 'אביזרים'],
      'description': 'חנות שכונתית למזון ואביזרים בסיסיים לכלבים וחתולים.',
      'open24h': false,
      'openingHours': {
        'sun': '09:00-19:00', 'mon': '09:00-19:00', 'tue': '09:00-19:00',
        'wed': '09:00-19:00', 'thu': '09:00-19:00', 'fri': '09:00-14:00',
      },
      'services': ['מזון', 'אביזרים'],
    },
    {
      'name': 'סופר פט נתניה',
      'type': 'store',
      'latitude': 32.3215, 'longitude': 34.8532,
      'rating': 4.5, 'reviewCount': 53,
      'imageUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=800',
      'address': 'הרצל, נתניה',
      'phoneNumber': '09-8765432',
      'tags': ['מבחר רחב', 'חיסונים בחנות'],
      'description': 'מרכז גדול עם מבחר רחב למזון, אביזרים ושירותי חיסון בחנות.',
      'website': 'https://superpet-netanya.demo.petpal.com',
      'open24h': false,
      'openingHours': {
        'sun': '09:00-21:00', 'mon': '09:00-21:00', 'tue': '09:00-21:00',
        'wed': '09:00-21:00', 'thu': '09:00-22:00', 'fri': '09:00-15:00',
      },
      'services': ['מזון', 'אביזרים', 'חיסונים'],
    },
  ];

  /// 3 distinct admin profiles. Written via the `seedMockAdmins` Cloud
  /// Function (Admin SDK) — firestore.rules blocks role:'admin' on every
  /// client create, including isMock writes, so this can't go through the
  /// batch below. See functions/index.js for why that bypass is safe.
  static const List<Map<String, String>> _adminProfiles = [
    {
      'name': 'איתן כהן',
      'phone': '050-1110001',
      'location': 'תל אביב',
      'bio': 'מנהל מערכת, אחראי על אימות ספקים ותוכן הפלטפורמה.',
    },
    {
      'name': 'רועי לוי',
      'phone': '050-1110002',
      'location': 'חיפה',
      'bio': 'מנהל מערכת, אחראי על דוחות משתמשים ובדיקת תלונות.',
    },
    {
      'name': 'נדב פרידמן',
      'phone': '050-1110003',
      'location': 'ירושלים',
      'bio': 'מנהל מערכת, אחראי על ניהול משתמשים ותמיכה כללית.',
    },
  ];

  /// 10 distinct service-provider profiles: 4 walk-only, 3 sitting-only,
  /// 3 offering both, each with different area, price model, pet types,
  /// available days and bio so no two providers look alike.
  static const List<Map<String, dynamic>> _providerProfiles = [
    {
      'offersWalk': true, 'offersSitting': false,
      'area': 'תל אביב',
      'bio': 'מטייל מקצועי לכלבים גדולים, מתמחה בטיולי בוקר ארוכים.',
      'petTypes': ['כלב'],
      'availableDays': ['א', 'ב', 'ג', 'ד', 'ה'],
      'isVerified': true, 'rating': 4.9, 'reviewCount': 34, 'experienceYears': 6,
      'walkDuration': 'שעה', 'walkPriceType': 'קבוע', 'walkPrice': '60',
    },
    {
      'offersWalk': true, 'offersSitting': false,
      'area': 'ירושלים',
      'bio': 'אוהב גורים, מציע טיולים קצרים ועדינים לכלבים צעירים.',
      'petTypes': ['כלב'],
      'availableDays': ['ש', 'א'],
      'isVerified': false, 'rating': 4.5, 'reviewCount': 11, 'experienceYears': 2,
      'walkDuration': '30 דקות', 'walkPriceType': 'לשעה', 'walkPrice': '45',
    },
    {
      'offersWalk': true, 'offersSitting': false,
      'area': 'חיפה',
      'bio': 'מארגן טיולים קבוצתיים לכלבים חברותיים באזור הכרמל.',
      'petTypes': ['כלב'],
      'availableDays': ['ב', 'ד', 'ו'],
      'isVerified': true, 'rating': 4.7, 'reviewCount': 22, 'experienceYears': 4,
      'walkDuration': 'שעה וחצי', 'walkPriceType': 'קבוע', 'walkPrice': '75',
    },
    {
      'offersWalk': true, 'offersSitting': false,
      'area': 'ראשון לציון',
      'bio': 'רץ עם כלבים אנרגטיים, טיולי ריצה וספורט יומיים.',
      'petTypes': ['כלב'],
      'availableDays': ['א', 'ג', 'ה', 'ש'],
      'isVerified': false, 'rating': 4.3, 'reviewCount': 8, 'experienceYears': 1,
      'walkDuration': 'גמיש', 'walkPriceType': 'לפי הסכמה', 'walkPrice': '50',
    },
    {
      'offersWalk': false, 'offersSitting': true,
      'area': 'פתח תקווה',
      'bio': 'מתמחה בחתולים, ביקורי בית יומיים עם האכלה וניקוי מגש.',
      'petTypes': ['חתול'],
      'availableDays': ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'],
      'isVerified': true, 'rating': 5.0, 'reviewCount': 41, 'experienceYears': 8,
      'sittingLocation': 'בבית הבעלים', 'sittingPriceType': 'ליום', 'sittingPrice': '70',
    },
    {
      'offersWalk': false, 'offersSitting': true,
      'area': 'אשדוד',
      'bio': 'שומר בבית הבעלים, ניסיון רב גם עם כלבים וגם עם חתולים.',
      'petTypes': ['כלב', 'חתול'],
      'availableDays': ['ג', 'ד', 'ה'],
      'isVerified': true, 'rating': 4.6, 'reviewCount': 19, 'experienceYears': 5,
      'sittingLocation': 'בבית הבעלים', 'sittingPriceType': 'ללילה', 'sittingPrice': '90',
    },
    {
      'offersWalk': false, 'offersSitting': true,
      'area': 'נתניה',
      'bio': 'בית גדול עם חצר סגורה, שמירה ביתית חמה ואישית.',
      'petTypes': ['חתול'],
      'availableDays': ['ו', 'ש'],
      'isVerified': false, 'rating': 4.2, 'reviewCount': 6, 'experienceYears': 1,
      'sittingLocation': 'בבית השומר', 'sittingPriceType': 'ללילה', 'sittingPrice': '80',
    },
    {
      'offersWalk': true, 'offersSitting': true,
      'area': 'רמת גן',
      'bio': 'ניסיון רב בטיולים ובשמירה, זמינות גמישה לאורך השבוע.',
      'petTypes': ['כלב', 'חתול'],
      'availableDays': ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'],
      'isVerified': true, 'rating': 4.8, 'reviewCount': 37, 'experienceYears': 9,
      'walkDuration': 'שעה', 'walkPriceType': 'קבוע', 'walkPrice': '65',
      'sittingLocation': 'שניהם', 'sittingPriceType': 'ללילה', 'sittingPrice': '85',
    },
    {
      'offersWalk': true, 'offersSitting': true,
      'area': 'חולון',
      'bio': 'מתמחה בגזעים קטנים, מציע גם טיולים קצרים וגם לינה.',
      'petTypes': ['כלב'],
      'availableDays': ['ב', 'ג', 'ד'],
      'isVerified': false, 'rating': 4.4, 'reviewCount': 14, 'experienceYears': 3,
      'walkDuration': '30 דקות', 'walkPriceType': 'לשעה', 'walkPrice': '40',
      'sittingLocation': 'בבית השומר', 'sittingPriceType': 'ליום', 'sittingPrice': '65',
    },
    {
      'offersWalk': true, 'offersSitting': true,
      'area': 'באר שבע',
      'bio': 'זמינות 24/7, גם טיולים יומיים וגם שמירה ארוכת טווח.',
      'petTypes': ['כלב', 'חתול'],
      'availableDays': ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'],
      'isVerified': true, 'rating': 4.9, 'reviewCount': 52, 'experienceYears': 12,
      'walkDuration': 'שעה וחצי', 'walkPriceType': 'לפי הסכמה', 'walkPrice': '70',
      'sittingLocation': 'בבית הבעלים', 'sittingPriceType': 'ליום', 'sittingPrice': '95',
    },
  ];

  // ─── NAME HELPERS (shared by user docs and community posts, so a post's
  // authorName always matches the actual seeded user doc it points at) ───

  static String _providerName(int i) =>
      '${_hebrewFirstNames[i % _hebrewFirstNames.length]} ${_hebrewLastNames[i % _hebrewLastNames.length]}';

  static String _providerPhoto(int i) => _providerPhotos[i % _providerPhotos.length];

  static String _ownerName(int i) =>
      '${_hebrewFirstNames[(i + 10) % _hebrewFirstNames.length]} ${_hebrewLastNames[(i + 3) % _hebrewLastNames.length]}';

  /// 18 community posts authored by users already seeded above (2 admins, 7
  /// providers, 9 owners) — providers post tips related to their own
  /// specialty, owners post photos/questions/recommendations. `authorIndex`
  /// indexes into _adminProfiles / _providerProfiles / the 15 owners.
  static const List<Map<String, dynamic>> _communityPosts = [
    {
      'authorType': 'admin', 'authorIndex': 0, 'type': 'post',
      'content': 'עדכון: הוספנו תהליך אימות חדש לספקים באפליקציה. נשמח לכל פידבק בנושא.',
    },
    {
      'authorType': 'admin', 'authorIndex': 1, 'type': 'post',
      'content': 'תזכורת לקהילה: ניתן לדווח על כל תוכן פוגעני ואנחנו מטפלים בו במהירות.',
    },
    {
      'authorType': 'provider', 'authorIndex': 0, 'type': 'tip',
      'content': 'טיפ לכלבים גדולים: טיול בוקר ארוך לפני שעות החום מונע התנהגות הרסנית בבית.',
      'imageUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=800',
    },
    {
      'authorType': 'provider', 'authorIndex': 1, 'type': 'tip',
      'content': 'עם גורים כדאי להתחיל בטיולים קצרים של 10-15 דקות ולהאריך בהדרגה.',
    },
    {
      'authorType': 'provider', 'authorIndex': 2, 'type': 'post',
      'content': 'טיול קבוצתי מהבוקר בכרמל, הכלבים נהנו מאוד!',
      'imageUrl': 'https://images.unsplash.com/photo-1601758124510-52d02ddb7cbd?auto=format&fit=crop&q=80&w=800',
    },
    {
      'authorType': 'provider', 'authorIndex': 4, 'type': 'tip',
      'content': 'חתולים אוהבים שגרה קבועה — האכלה וניקוי מגש בשעות זהות מפחיתים סטרס.',
    },
    {
      'authorType': 'provider', 'authorIndex': 5, 'type': 'post',
      'content': 'סיימתי שמירה משותפת על כלב וחתול באותו בית — הצמד התחבב עליי מהר!',
      'imageUrl': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&q=80&w=800',
    },
    {
      'authorType': 'provider', 'authorIndex': 7, 'type': 'tip',
      'content': 'לפני שמירה ראשונה כדאי לבקש מהבעלים רשימת הרגלים ואלרגיות של החיה.',
    },
    {
      'authorType': 'provider', 'authorIndex': 9, 'type': 'post',
      'content': 'מתחיל לקבל בקשות גם לסופי שבוע — מי שצריך שמירה דחופה מוזמן לפנות.',
      'imageUrl': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=800',
    },
    {
      'authorType': 'owner', 'authorIndex': 0, 'type': 'post',
      'content': 'החתול שלי גילה את הספה החדשה ולא מתכוון לעזוב אותה :)',
      'imageUrl': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&q=80&w=800',
    },
    {
      'authorType': 'owner', 'authorIndex': 1, 'type': 'post',
      'content': 'מישהו מכיר וטרינר טוב באזור ראשון לציון? הכלב שלי צריך טיפול שיניים.',
    },
    {
      'authorType': 'owner', 'authorIndex': 3, 'type': 'post',
      'content': 'טיול בוקר עם הכלב בפארק הירקון — אווירה מושלמת היום.',
      'imageUrl': 'https://images.unsplash.com/photo-1601758124510-52d02ddb7cbd?auto=format&fit=crop&q=80&w=800',
    },
    {
      'authorType': 'owner', 'authorIndex': 5, 'type': 'tip',
      'content': 'גיליתי שכפית דלעת מרוסקת בקערת האוכל עוזרת לכלב שלי עם בעיות עיכול.',
    },
    {
      'authorType': 'owner', 'authorIndex': 7, 'type': 'post',
      'content': 'הצטרפתי לקהילה! יש לי כלבלב חדש בבית, מאוד נרגש.',
      'imageUrl': 'https://images.unsplash.com/photo-1517849845537-4d257902454a?auto=format&fit=crop&q=80&w=800',
    },
    {
      'authorType': 'owner', 'authorIndex': 9, 'type': 'post',
      'content': 'ביקרתי עם החתולה שלי בווטרינר לבדיקה שנתית, הכל תקין ב"ה.',
    },
    {
      'authorType': 'owner', 'authorIndex': 11, 'type': 'post',
      'content': 'מישהו מכיר שומר טוב לכלב גדול לסוף השבוע הקרוב?',
    },
    {
      'authorType': 'owner', 'authorIndex': 13, 'type': 'post',
      'content': 'הארנב שלי למד לקפוץ על הספה בכוחות עצמו היום, גאה בו.',
      'imageUrl': 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&q=80&w=800',
    },
    {
      'authorType': 'owner', 'authorIndex': 14, 'type': 'post',
      'content': 'מצאתי פינת כלבים נהדרת קרוב לבית, ממליץ לכל מי שגר בסביבה.',
      'imageUrl': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&q=80&w=800',
    },
  ];

  /// 12 bookings — 6 walking requests, 6 caring (sitting) requests — one for
  /// each BookingStatus value on each service type, so the full state machine
  /// is represented. providerIndex only ever points at a provider that
  /// actually offers that serviceType (see _providerProfiles' offersWalk /
  /// offersSitting flags). dayOffset is relative to today: negative = past
  /// (used for completed bookings), positive = future.
  static const List<Map<String, dynamic>> _bookingProfiles = [
    // ── Walking requests (providerIndex offers walk: 0,1,2,3,7,8,9) ──
    {
      'ownerIndex': 0, 'providerIndex': 0, 'serviceType': 'walk', 'status': 'pending',
      'dayOffset': 3, 'specialInstructions': 'הכלב נוטה לפחד מאופניים, מבקש לשמור מרחק.',
    },
    {
      'ownerIndex': 1, 'providerIndex': 1, 'serviceType': 'walk', 'status': 'accepted',
      'dayOffset': 5,
    },
    {
      'ownerIndex': 2, 'providerIndex': 2, 'serviceType': 'walk', 'status': 'awaitingConfirmation',
      'dayOffset': -1,
    },
    {
      'ownerIndex': 3, 'providerIndex': 3, 'serviceType': 'walk', 'status': 'completed',
      'dayOffset': -10,
    },
    {
      'ownerIndex': 4, 'providerIndex': 7, 'serviceType': 'walk', 'status': 'declined',
      'dayOffset': 2, 'providerNote': 'מצטער, התאריך הזה כבר תפוס.',
    },
    {
      'ownerIndex': 5, 'providerIndex': 8, 'serviceType': 'walk', 'status': 'cancelled',
      'dayOffset': 4,
    },
    // ── Caring / sitting requests (providerIndex offers sitting: 4,5,6,7,8,9) ──
    {
      'ownerIndex': 6, 'providerIndex': 4, 'serviceType': 'sitting', 'status': 'pending',
      'dayOffsetStart': 6, 'dayOffsetEnd': 9,
      'specialInstructions': 'החתולה זקוקה לתרופה פעמיים ביום, הסבר יישלח בצ׳אט.',
    },
    {
      'ownerIndex': 7, 'providerIndex': 5, 'serviceType': 'sitting', 'status': 'accepted',
      'dayOffsetStart': 8, 'dayOffsetEnd': 11,
    },
    {
      'ownerIndex': 8, 'providerIndex': 6, 'serviceType': 'sitting', 'status': 'awaitingConfirmation',
      'dayOffsetStart': -4, 'dayOffsetEnd': -1,
    },
    {
      'ownerIndex': 9, 'providerIndex': 7, 'serviceType': 'sitting', 'status': 'completed',
      'dayOffsetStart': -14, 'dayOffsetEnd': -11,
    },
    {
      'ownerIndex': 10, 'providerIndex': 8, 'serviceType': 'sitting', 'status': 'declined',
      'dayOffsetStart': 3, 'dayOffsetEnd': 5,
      'providerNote': 'אין לי פניות לכלבים גדולים בתאריך הזה.',
    },
    {
      'ownerIndex': 11, 'providerIndex': 9, 'serviceType': 'sitting', 'status': 'cancelled',
      'dayOffsetStart': 7, 'dayOffsetEnd': 9,
    },
  ];

  /// 6 moderation reports exercising the AI triage pipeline end-to-end.
  /// targetId indexes into _communityPosts ('seed_post_$i', as written in
  /// seedData section 4) — checked against that list's actual content, not
  /// assumed, so fetchReportedContent resolves the text described below:
  /// - seed_post_4 (provider2's Carmel walk post) is reported by two
  ///   different owners for the same reason (clustering: count 2).
  /// - seed_post_8 (provider9's weekend-availability post) — a self-promo
  ///   flagged as inappropriate; genuinely borderline, not false.
  /// - seed_post_6 (provider5's "finished a joint dog+cat sitting" post) and
  ///   seed_post_10 (owner1's genuine vet recommendation request) are
  ///   "false-flag" cases — a severe-sounding reason on content that's
  ///   actually innocuous, to check the AI judges the fetched content rather
  ///   than just trusting the claim.
  /// - One ReportType.user report (harassment/threat) tests escalation on a
  ///   non-post target.
  static const List<Map<String, dynamic>> _reportProfiles = [
    {
      'type': 'post', 'targetId': 'seed_post_4', 'reporterIndex': 2,
      'reporterType': 'owner', 'reason': 'ספאם ופרסומת',
    },
    {
      'type': 'post', 'targetId': 'seed_post_4', 'reporterIndex': 4,
      'reporterType': 'owner', 'reason': 'ספאם ופרסומת',
    },
    {
      'type': 'post', 'targetId': 'seed_post_8', 'reporterIndex': 6,
      'reporterType': 'owner', 'reason': 'תוכן לא הולם',
    },
    {
      // False-flag test: real content is a wholesome sitting update.
      'type': 'post', 'targetId': 'seed_post_6', 'reporterIndex': 8,
      'reporterType': 'owner', 'reason': 'אכזריות לבעלי חיים, תוכן מזעזע',
    },
    {
      // False-flag test: real content is a genuine vet recommendation request.
      'type': 'post', 'targetId': 'seed_post_10', 'reporterIndex': 3,
      'reporterType': 'provider', 'reason': 'ספאם',
    },
    {
      'type': 'user', 'targetId': 'seed_provider_4', 'reporterIndex': 10,
      'reporterType': 'owner',
      'reason': 'הטרדה — המשתמש שולח לי הודעות מאיימות בצ\'אט ולא מפסיק',
    },
  ];

  // ─── PUBLIC METHODS ───

  /// Seeds exactly: 3 admins, 10 service providers (4 walk-only, 3
  /// sitting-only, 3 offering both), 15 pet owners, 12 points of interest
  /// (4 parks, 4 vets, 4 stores), 18 community posts authored by those same
  /// users, 12 booking requests (6 walking, 6 caring) covering every status
  /// in the state machine, 6 moderation reports exercising AI triage
  /// (clustering, a false-flag case, and a user-type harassment report — see
  /// _reportProfiles), and — when [currentUserId] is provided — 2 real pets
  /// plus 2 walking requests + 2 caring requests on the open request board,
  /// all owned by the real signed-in account and pointing at the same two
  /// pets (mock accounts can't sign in, so this is the only way seeded
  /// pets/requests show up on "החיות שלי" / "My Requests"). Nothing else (no
  /// reviews).
  Future<void> seedData({String? currentUserId}) async {
    // Clear first so re-running is idempotent. Without this, a second run does
    // `set()` over the existing seed_* docs — which Firestore evaluates as an
    // UPDATE, not a create. The users/services update rules guard by
    // ownership (or isAdmin) and have no isMock bypass, so a non-admin caller
    // gets permission-denied on every re-seed. Deleting first makes every
    // set() a genuine create again, where the isMock bypass applies.
    await clearMockData();

    await FirebaseFunctions.instance.httpsCallable('seedMockAdmins').call({
      'admins': _adminProfiles,
    });

    // Each section commits its own batch instead of one mega-batch. A
    // Firestore batch is all-or-nothing, so a single rejected write used to
    // fail everything with one opaque "permission-denied" and no indication
    // of which collection caused it. Splitting by section means a failure
    // here names the exact section, instead of forcing a guess.
    var batch = _firestore.batch();

    // 1. Create Providers — 10 distinct profiles from _providerProfiles.
    for (int i = 0; i < _providerProfiles.length; i++) {
      final profile = _providerProfiles[i];
      final pid = 'seed_provider_$i';
      final name = _providerName(i);
      final photoUrl = _providerPhoto(i);
      final area = profile['area'] as String;

      batch.set(_firestore.collection('users').doc(pid), {
        'uid': pid,
        'name': name,
        'email': 'provider$i@demo.petpal.com',
        'phone': '050-200${i.toString().padLeft(4, '0')}',
        'photoUrl': photoUrl,
        'bio': profile['bio'],
        'location': area,
        'role': UserRole.serviceProvider.firestoreValue,
        'isVerified': profile['isVerified'],
        'rating': profile['rating'],
        'totalReviews': profile['reviewCount'],
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (profile['offersWalk'] == true) {
        batch.set(_firestore.collection('walk_services').doc('walk_$pid'), {
          'providerUid': pid,
          'providerName': name,
          'providerPhotoUrl': photoUrl,
          'area': area,
          'priceText': profile['walkPrice'],
          'priceType': profile['walkPriceType'],
          'bio': profile['bio'],
          'duration': profile['walkDuration'],
          'petTypes': profile['petTypes'],
          'availableDays': profile['availableDays'],
          'isActive': true,
          'rating': profile['rating'],
          'reviewCount': profile['reviewCount'],
          'isMock': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (profile['offersSitting'] == true) {
        batch.set(_firestore.collection('sitting_services').doc('sit_$pid'), {
          'providerUid': pid,
          'providerName': name,
          'providerPhotoUrl': photoUrl,
          'area': area,
          'priceText': profile['sittingPrice'],
          'priceType': profile['sittingPriceType'],
          'bio': profile['bio'],
          'petTypes': profile['petTypes'],
          'availableDays': profile['availableDays'],
          'sittingLocation': profile['sittingLocation'],
          'isActive': true,
          'rating': profile['rating'],
          'reviewCount': profile['reviewCount'],
          'isMock': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await _commitLabeled(batch, 'providers (users/walk_services/sitting_services)');
    batch = _firestore.batch();

    // 2. Create Owners & Pets — 15 distinct owners; every 3rd owns 2 pets.
    // Pet attributes cycle deterministically through the breed/color lists so
    // no two pets end up with the same profile. Each owner's first pet is
    // captured in ownerFirstPet so step 5 (bookings) can reference a real
    // seeded pet instead of inventing a disconnected one.
    var petCounter = 0;
    final List<Map<String, dynamic>> ownerFirstPet = [];
    for (int i = 0; i < 15; i++) {
      final oid = 'seed_owner_$i';
      final area = _areas[i % _areas.length];
      final name = _ownerName(i);

      batch.set(_firestore.collection('users').doc(oid), {
        'uid': oid,
        'name': name,
        'email': 'owner$i@demo.petpal.com',
        'phone': '050-300${i.toString().padLeft(4, '0')}',
        'location': area,
        'bio': 'תושב $area, אוהב בעלי חיים ומטייל איתם באזור.',
        'role': UserRole.petOwner.firestoreValue,
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final numPets = i % 3 == 0 ? 2 : 1;
      for (int j = 0; j < numPets; j++) {
        final petId = 'pet_${oid}_$j';
        final isDog = petCounter % 2 == 0;
        final type = isDog ? 'כלב' : 'חתול';
        final breed = isDog
            ? _dogBreeds[petCounter % _dogBreeds.length]
            : _catBreeds[petCounter % _catBreeds.length];
        final petName = _petNames[petCounter % _petNames.length];
        final petImageUrl = _petPhotos[petCounter % _petPhotos.length];

        batch.set(
          _firestore.collection('users').doc(oid).collection('pets').doc(petId),
          {
            'ownerUid': oid,
            'name': petName,
            'type': type,
            'breed': breed,
            'gender': petCounter % 2 == 0 ? 'זכר' : 'נקבה',
            'imageUrl': petImageUrl,
            'ageYears': 1 + (petCounter % 12),
            'weightKg': isDog
                ? (5 + (petCounter % 30)).toDouble()
                : (2 + (petCounter % 6)).toDouble(),
            'color': _petColors[petCounter % _petColors.length],
            'isVaccinated': petCounter % 4 != 0,
            'isMock': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
        if (j == 0) {
          ownerFirstPet.add({'name': petName, 'type': type, 'imageUrl': petImageUrl});
        }
        petCounter++;
      }
    }
    await _commitLabeled(batch, 'owners and pets (users/pets)');
    batch = _firestore.batch();

    // 3. Create POIs — 12 distinct points of interest from _poiProfiles.
    for (int i = 0; i < _poiProfiles.length; i++) {
      batch.set(_firestore.collection('pois').doc('seed_poi_$i'), {
        ..._poiProfiles[i],
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await _commitLabeled(batch, 'POIs (pois)');
    batch = _firestore.batch();

    // 4. Create Community Posts — 18 posts authored by the admins, providers
    // and owners seeded above (authorUid/authorName resolved from the same
    // index the user doc was created with, so they always match).
    for (int i = 0; i < _communityPosts.length; i++) {
      final post = _communityPosts[i];
      final authorType = post['authorType'] as String;
      final authorIndex = post['authorIndex'] as int;

      final authorUid = switch (authorType) {
        'admin' => 'seed_admin_$authorIndex',
        'provider' => 'seed_provider_$authorIndex',
        _ => 'seed_owner_$authorIndex',
      };
      final authorName = switch (authorType) {
        'admin' => _adminProfiles[authorIndex]['name']!,
        'provider' => _providerName(authorIndex),
        _ => _ownerName(authorIndex),
      };
      final authorPhotoUrl =
          authorType == 'provider' ? _providerPhoto(authorIndex) : null;
      final imageUrl = post['imageUrl'] as String?;

      batch.set(_firestore.collection('posts').doc('seed_post_$i'), {
        'authorUid': authorUid,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'type': post['type'],
        'content': post['content'],
        'imageUrls': imageUrl != null ? [imageUrl] : <String>[],
        'likes': <String>[],
        'commentCount': 0,
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await _commitLabeled(batch, 'community posts (posts)');
    batch = _firestore.batch();

    // 5. Create Bookings — 6 walking requests + 6 caring (sitting) requests
    // from _bookingProfiles, each tied to a real seeded owner/pet/provider.
    final now = DateTime.now();
    for (int i = 0; i < _bookingProfiles.length; i++) {
      final b = _bookingProfiles[i];
      final ownerIndex = b['ownerIndex'] as int;
      final providerIndex = b['providerIndex'] as int;
      final serviceType = b['serviceType'] as String;
      final isWalk = serviceType == 'walk';
      final providerProfile = _providerProfiles[providerIndex];
      final pet = ownerFirstPet[ownerIndex];

      final sittingLocation = providerProfile['sittingLocation'] as String?;
      final sittingType = sittingLocation == 'בבית השומר'
          ? 'atSitterHome'
          : sittingLocation == 'שניהם' && i.isEven
              ? 'atSitterHome'
              : 'atOwnerHome';

      batch.set(_firestore.collection('booking_requests').doc('seed_booking_$i'), {
        'ownerUid': 'seed_owner_$ownerIndex',
        'ownerName': _ownerName(ownerIndex),
        'ownerPhotoUrl': null,
        'providerUid': 'seed_provider_$providerIndex',
        'providerName': _providerName(providerIndex),
        'providerPhotoUrl': _providerPhoto(providerIndex),
        'serviceId': isWalk ? 'walk_seed_provider_$providerIndex' : 'sit_seed_provider_$providerIndex',
        'serviceType': serviceType,
        'petName': pet['name'],
        'petType': pet['type'],
        'petImageUrl': pet['imageUrl'],
        'requestedDate': isWalk
            ? Timestamp.fromDate(now.add(Duration(days: b['dayOffset'] as int)))
            : null,
        'startDate': isWalk
            ? null
            : Timestamp.fromDate(now.add(Duration(days: b['dayOffsetStart'] as int))),
        'endDate': isWalk
            ? null
            : Timestamp.fromDate(now.add(Duration(days: b['dayOffsetEnd'] as int))),
        'specialInstructions': b['specialInstructions'],
        'status': b['status'],
        'providerNote': b['providerNote'],
        'sittingType': isWalk ? null : sittingType,
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await _commitLabeled(batch, 'bookings (booking_requests)');

    // 6. Create moderation reports — see _reportProfiles for what each one
    // tests. Written as a raw map (matching ContentReport.toFirestore() plus
    // isMock) rather than through ModerationRepository, consistent with the
    // rest of this file writing Firestore directly. Doc id is deterministic
    // (type_targetId_reporterId), matching ModerationRepository.submitReport,
    // so re-seeding overwrites these in place instead of duplicating them.
    batch = _firestore.batch();
    for (final r in _reportProfiles) {
      final reporterType = r['reporterType'] as String;
      final reporterIndex = r['reporterIndex'] as int;
      final reporterId = reporterType == 'provider'
          ? 'seed_provider_$reporterIndex'
          : 'seed_owner_$reporterIndex';
      final type = r['type'] as String;
      final targetId = r['targetId'] as String;
      final id = '${type}_${targetId}_$reporterId';

      batch.set(_firestore.collection('reports').doc(id), {
        'targetId': targetId,
        'type': type,
        'reporterId': reporterId,
        'reason': r['reason'],
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedBy': null,
        'resolvedAt': null,
        'aiSeverity': null,
        'aiCategory': null,
        'aiAction': null,
        'aiRationale': null,
        'isMock': true,
      });
    }
    await _commitLabeled(batch, 'reports (reports)');

    // 7, 8 & 9. Real pets + walking/caring requests for the currently
    // signed-in user. The requests are a *different* model from
    // booking_requests — an open request board
    // (lib/features/walks & sitting/.../*_requests), shown on the "My
    // Requests" home tab, queried by
    // `where('ownerUid', isEqualTo: <the real signed-in uid>)`. Mock
    // seed_owner_X accounts can never sign in, so this is the only way for
    // seeded requests to actually appear on that screen. The two pets are
    // written first as real documents under users/{uid}/pets, and every
    // request below points at one of them by name/type/image — so "My
    // Requests" and "החיות שלי" show the same two animals, not disconnected
    // placeholder names.
    final uid = currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      final ownerName = user?.displayName ?? user?.email ?? 'משתמש';
      final ownerPhotoUrl = user?.photoURL;
      final now2 = DateTime.now();

      // The dog and the cat every request below refers back to.
      const dog = {
        'name': 'מקס', 'type': 'כלב', 'breed': 'לברדור', 'gender': 'זכר',
        'ageYears': 3, 'weightKg': 28.0, 'color': 'זהבי',
      };
      const cat = {
        'name': 'בל', 'type': 'חתול', 'breed': 'בריטי קצר שיער', 'gender': 'נקבה',
        'ageYears': 2, 'weightKg': 4.0, 'color': 'אפור',
      };
      final dogPhoto = _petPhotos[0];
      final catPhoto = _petPhotos[1];

      batch = _firestore.batch();
      batch.set(
        _firestore.collection('users').doc(uid).collection('pets').doc('pet_${uid}_0'),
        {
          'ownerUid': uid,
          'name': dog['name'],
          'type': dog['type'],
          'breed': dog['breed'],
          'gender': dog['gender'],
          'imageUrl': dogPhoto,
          'ageYears': dog['ageYears'],
          'weightKg': dog['weightKg'],
          'color': dog['color'],
          'isVaccinated': true,
          'isMock': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
      batch.set(
        _firestore.collection('users').doc(uid).collection('pets').doc('pet_${uid}_1'),
        {
          'ownerUid': uid,
          'name': cat['name'],
          'type': cat['type'],
          'breed': cat['breed'],
          'gender': cat['gender'],
          'imageUrl': catPhoto,
          'ageYears': cat['ageYears'],
          'weightKg': cat['weightKg'],
          'color': cat['color'],
          'isVaccinated': true,
          'isMock': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
      await _commitLabeled(batch, 'my pets (users/$uid/pets)');

      // walk_requests/sitting_requests use English petType ('dog'/'cat'),
      // unlike the Hebrew Pet.type field above — matching each collection's
      // own fromFirestore() convention, not assuming consistency across them.
      batch = _firestore.batch();
      batch.set(_firestore.collection('walk_requests').doc(), {
        'ownerUid': uid,
        'ownerName': ownerName,
        'ownerPhotoUrl': ownerPhotoUrl,
        'petName': dog['name'],
        'petType': 'dog',
        'petGender': 'male',
        'petImageUrl': dogPhoto,
        'preferredDate': Timestamp.fromDate(now2.add(const Duration(days: 2))),
        'preferredTime': 'בוקר',
        'duration': '30 דקות',
        'area': _areas[0],
        'specialInstructions': 'הכלב חברותי מאוד, אוהב טיולים בפארק.',
        'budget': '50',
        'status': 'open',
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_firestore.collection('walk_requests').doc(), {
        'ownerUid': uid,
        'ownerName': ownerName,
        'ownerPhotoUrl': ownerPhotoUrl,
        'petName': dog['name'],
        'petType': 'dog',
        'petGender': 'male',
        'petImageUrl': dogPhoto,
        'preferredDate': Timestamp.fromDate(now2.add(const Duration(days: 1))),
        'preferredTime': 'ערב',
        'duration': 'שעה',
        'area': _areas[1],
        'budget': '70',
        'status': 'taken',
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _commitLabeled(batch, 'walking requests (walk_requests)');

      batch = _firestore.batch();
      batch.set(_firestore.collection('sitting_requests').doc(), {
        'ownerUid': uid,
        'ownerName': ownerName,
        'ownerPhotoUrl': ownerPhotoUrl,
        'petName': cat['name'],
        'petType': 'cat',
        'petGender': 'female',
        'petImageUrl': catPhoto,
        'startDate': Timestamp.fromDate(now2.add(const Duration(days: 5))),
        'endDate': Timestamp.fromDate(now2.add(const Duration(days: 8))),
        'sittingType': 'atSitterHome',
        'area': _areas[0],
        'specialInstructions': 'החתול זקוק לאוכל מיוחד פעמיים ביום.',
        'budget': '80 לילה',
        'status': 'open',
        'isPublicJob': true,
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_firestore.collection('sitting_requests').doc(), {
        'ownerUid': uid,
        'ownerName': ownerName,
        'ownerPhotoUrl': ownerPhotoUrl,
        'petName': dog['name'],
        'petType': 'dog',
        'petGender': 'male',
        'petImageUrl': dogPhoto,
        'startDate': Timestamp.fromDate(now2.add(const Duration(days: 10))),
        'endDate': Timestamp.fromDate(now2.add(const Duration(days: 12))),
        'sittingType': 'atOwnerHome',
        'area': _areas[0],
        'budget': '90 לילה',
        'status': 'open',
        'isPublicJob': true,
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _commitLabeled(batch, 'caring requests (sitting_requests)');
    }
  }

  /// Commits [batch] and, on failure, rethrows with [label] prefixed so a
  /// permission-denied (or any other) error names the exact section that
  /// failed instead of leaving every section as an equally-likely suspect.
  Future<void> _commitLabeled(WriteBatch batch, String label) async {
    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Seeding failed at section "$label": $e');
    }
  }

  /// Clears all mock data from Firestore safely
  Future<void> clearMockData() async {
    final collections = [
      'users',
      'pets',
      'sitting_services',
      'sitting_requests',
      'walk_services',
      'walk_requests',
      'reviews',
      'booking_requests',
      'pois',
      'posts',
    ];

    for (final collection in collections) {
      final snapshot = collection == 'pets'
          ? await _firestore
              .collectionGroup('pets')
              .where('isMock', isEqualTo: true)
              .get()
          : await _firestore
              .collection(collection)
              .where('isMock', isEqualTo: true)
              .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        // Double check email pattern for users
        if (collection == 'users') {
          final email = doc.data()['email']?.toString() ?? '';
          if (!email.endsWith('@demo.petpal.com')) continue;
        }
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
