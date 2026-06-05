import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';
import 'dart:math';

class SeedService {
  final FirebaseFirestore _firestore;
  final Random _random = Random();

  SeedService({required FirebaseFirestore firestore}) : _firestore = firestore;

  // ─── CURATED HEBREW DATA ───

  static const List<String> _hebrewFirstNames = [
    'איתי', 'נועם', 'דניאל', 'אורי', 'איתן', 'יונתן', 'גיא', 'יהונתן', 'אריאל', 'משה',
    'נועה', 'תמר', 'מאיה', 'אביגיל', 'איילה', 'יעל', 'שירה', 'מיכל', 'עדי', 'טל'
  ];

  static const List<String> _hebrewLastNames = [
    'כהן', 'לוי', 'מזרחי', 'פרץ', 'ביטון', 'דהן', 'אברהם', 'פרידמן', 'מלכה', 'אזולאי'
  ];

  static const List<String> _areas = [
    'תל אביב', 'ירושלים', 'חיפה', 'ראשון לציון', 'פתח תקווה', 'אשדוד', 'נתניה', 'באר שבע', 'רמת גן', 'חולון'
  ];

  static const List<String> _providerBios = [
    'אוהב חיות מושבע, מטפל בכלב וחתול כבר 10 שנים. מציע שירותי טיול ולינה באווירה ביתית.',
    'סטודנטית לרפואת שיניים עם הרבה זמן פנוי ואהבה ענקית לכלבים. אשמח לארח את הכלב שלכם אצלי בבית.',
    'מומחה להתנהגות כלבים, מציע טיולים ארוכים ומאתגרים לכלבים עם הרבה אנרגיה.',
    'גמלאית עם בית גדול וחצר סגורה, מחפשת חברה של חברים על ארבע. יחס אישי וחם מובטח.',
    'מטפלת מקצועית בחתולים, מציעה ביקורי בית, האכלה וזמן משחק.',
  ];

  static const List<String> _petNames = [
    'לואי', 'סימבה', 'בל', 'לוסי', 'מקס', 'צ׳ארלי', 'רוקי', 'לולה', 'מיילו', 'ג׳וי'
  ];

  static const List<String> _reviews = [
    'שירות מעולה! הכלב שלי חזר שמח ומרוצה. מומלץ בחום.',
    'מטפל מדהים, שלח לי תמונות ועדכונים כל יום. הרגשתי רגועה לגמרי.',
    'מקסים, סבלני ומאוד מקצועי. הכלב שלי התחבר אליו מיד.',
    'תודה רבה על הטיפול המסור! הבית היה נקי והחתול היה רגוע כשחזרנו.',
    'היה פשוט נהדר. בטוח נזמין שוב.',
  ];

  static const List<String> _vibeTags = [
    'סבלני', 'אחראי', 'אוהב', 'דייקן', 'מעדכן בתמונות', 'בית נקי', 'חצר גדולה', 'ניסיון עם גורים'
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

  static const List<Map<String, dynamic>> _pois = [
    {
      'name': 'גן מאיר (גינת כלבים)',
      'type': 'park',
      'latitude': 32.0747,
      'longitude': 34.7733,
      'rating': 4.8,
      'reviewCount': 120,
      'tags': ['מרכזי', 'חולי', 'מוצל'],
      'address': 'המלך ג׳ורג׳, תל אביב',
    },
    {
      'name': 'גינת כלבים פארק הירקון',
      'type': 'park',
      'latitude': 32.0988,
      'longitude': 34.8094,
      'rating': 4.9,
      'reviewCount': 350,
      'tags': ['ענק', 'דשא', 'על המים'],
      'address': 'גני יהושע, תל אביב',
    },
    {
      'name': 'בית חולים וטרינרי תורן (חירום)',
      'type': 'vet',
      'latitude': 32.0853,
      'longitude': 34.7818,
      'isEmergency': true,
      'rating': 4.7,
      'reviewCount': 85,
      'tags': ['24/7', 'מומחים', 'כירורגיה'],
      'address': 'אבן גבירול, תל אביב',
      'phoneNumber': '03-1234567',
    },
    {
      'name': 'מרפאה וטרינרית ד"ר דוליטל',
      'type': 'vet',
      'latitude': 32.0625,
      'longitude': 34.7711,
      'rating': 4.5,
      'reviewCount': 42,
      'tags': ['חיסונים', 'יחס אישי'],
      'address': 'רוטשילד, תל אביב',
    },
    {
      'name': 'פט-ביי (חנות חיות)',
      'type': 'store',
      'latitude': 32.0722,
      'longitude': 34.7822,
      'rating': 4.6,
      'reviewCount': 156,
      'tags': ['משלוחים', 'מזון רפואי'],
      'address': 'דיזנגוף, תל אביב',
    },
    {
      'name': 'אנימל-שופ',
      'type': 'store',
      'latitude': 32.0455,
      'longitude': 34.7555,
      'rating': 4.4,
      'reviewCount': 98,
      'tags': ['זול', 'ציוד מקצועי'],
      'address': 'יפו, תל אביב',
    },
  ];

  // ─── PUBLIC METHODS ───

  /// Seeds a full demo environment
  Future<void> seedData({String? currentUserId}) async {
    final batch = _firestore.batch();
    
    // 1. Create Providers
    final List<String> providerIds = [];
    final Map<String, String> providerNames = {};
    for (int i = 0; i < 8; i++) {
      final pid = 'seed_provider_$i';
      providerIds.add(pid);
      final name = '${_hebrewFirstNames[_random.nextInt(_hebrewFirstNames.length)]} ${_hebrewLastNames[_random.nextInt(_hebrewLastNames.length)]}';
      providerNames[pid] = name;
      
      // User Doc
      batch.set(_firestore.collection('users').doc(pid), {
        'uid': pid,
        'name': name,
        'email': 'provider$i@demo.petpal.com',
        'role': UserRole.serviceProvider.firestoreValue,
        'isVerified': true,
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Service Doc
      batch.set(_firestore.collection('sitting_services').doc('service_$pid'), {
        'providerUid': pid,
        'providerName': name,
        'providerPhotoUrl': _providerPhotos[_random.nextInt(_providerPhotos.length)],
        'area': _areas[_random.nextInt(_areas.length)],
        'priceText': '${50 + _random.nextInt(100)}',
        'priceType': 'ללילה',
        'bio': _providerBios[_random.nextInt(_providerBios.length)],
        'petTypes': ['dog', 'cat'],
        'availableDays': ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'],
        'sittingLocation': 'בבית השומר',
        'isActive': true,
        'experienceYears': 1 + _random.nextInt(10),
        'isVerified': _random.nextBool(),
        'rating': 4.0 + (_random.nextDouble() * 1.0),
        'reviewCount': 5 + _random.nextInt(20),
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. Create Owners & Pets
    final List<String> ownerIds = [];
    for (int i = 0; i < 5; i++) {
      final oid = 'seed_owner_$i';
      ownerIds.add(oid);
      final ownerName = '${_hebrewFirstNames[_random.nextInt(_hebrewFirstNames.length)]} ${_hebrewLastNames[_random.nextInt(_hebrewLastNames.length)]}';

      batch.set(_firestore.collection('users').doc(oid), {
        'uid': oid,
        'name': ownerName,
        'email': 'owner$i@demo.petpal.com',
        'role': UserRole.petOwner.firestoreValue,
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Pets for this owner
      for (int j = 0; j < 1 + _random.nextInt(2); j++) {
        final petId = 'pet_${oid}_$j';
        batch.set(_firestore.collection('users').doc(oid).collection('pets').doc(petId), {
          'ownerUid': oid,
          'name': _petNames[_random.nextInt(_petNames.length)],
          'type': _random.nextBool() ? 'dog' : 'cat',
          'imageUrl': _petPhotos[_random.nextInt(_petPhotos.length)],
          'isMock': true,
        });
      }
    }

    // 3. Create Bookings (Historical & Active)
    for (int i = 0; i < 20; i++) {
      final bid = 'seed_booking_$i';
      final providerId = providerIds[_random.nextInt(providerIds.length)];
      final ownerId = ownerIds[_random.nextInt(ownerIds.length)];
      
      final status = i < 15 ? 'closed' : 'open'; // Mostly historical
      
      batch.set(_firestore.collection('sitting_requests').doc(bid), {
        'ownerUid': ownerId,
        'ownerName': 'משתמש דמו',
        'petName': _petNames[_random.nextInt(_petNames.length)],
        'petType': _random.nextBool() ? 'dog' : 'cat',
        'area': _areas[_random.nextInt(_areas.length)],
        'sittingType': 'atSitterHome',
        'status': status,
        'sitterUid': providerId,
        'sitterName': 'שומר דמו',
        'startDate': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 30 - i))),
        'endDate': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 28 - i))),
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Create Reviews for Closed Bookings (Write to 'reviews' collection)
      if (status == 'closed') {
        batch.set(_firestore.collection('reviews').doc(bid), {
          'bookingId': bid,
          'reviewerUid': ownerId,
          'reviewerName': 'משתמש דמו',
          'reviewerPhotoUrl': null,
          'providerId': providerId,
          'rating': 4 + _random.nextInt(2), // 4 or 5 stars
          'comment': _reviews[_random.nextInt(_reviews.length)],
          'isMock': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // 5. Seed Direct Bookings for Current Logged-in User
    if (currentUserId != null && currentUserId.isNotEmpty) {
      // Ensure current user has a seeded pet
      final userPetId = 'pet_${currentUserId}_0';
      batch.set(_firestore.collection('users').doc(currentUserId).collection('pets').doc(userPetId), {
        'ownerUid': currentUserId,
        'name': 'רוקי',
        'type': 'dog',
        'imageUrl': _petPhotos[0],
        'isMock': true,
      });

      // Create 2 accepted bookings (1 walk, 1 sitting)
      for (int i = 0; i < 2; i++) {
        final bid = 'mock_direct_booking_${currentUserId}_$i';
        final providerId = providerIds[i % providerIds.length];
        final providerName = providerNames[providerId] ?? 'נותן שירות דמו';
        final isWalk = i == 0;

        batch.set(_firestore.collection('booking_requests').doc(bid), {
          'ownerUid': currentUserId,
          'ownerName': 'בעלים נוכחי',
          'ownerPhotoUrl': null,
          'providerUid': providerId,
          'providerName': providerName,
          'providerPhotoUrl': _providerPhotos[i % _providerPhotos.length],
          'serviceId': isWalk ? 'walk_service_$providerId' : 'service_$providerId',
          'serviceType': isWalk ? 'walk' : 'sitting',
          'petName': 'רוקי',
          'petType': 'כלב',
          'petImageUrl': _petPhotos[0],
          'status': 'accepted',
          'createdAt': FieldValue.serverTimestamp(),
          'isMock': true,
        });
      }
    }

    // 6. Seed POIs
    for (int i = 0; i < _pois.length; i++) {
      final poiData = _pois[i];
      batch.set(_firestore.collection('pois').doc('seed_poi_$i'), {
        ...poiData,
        'isMock': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
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
