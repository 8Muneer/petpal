import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/features/lost_and_found/data/models/lost_found_post_model.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';

class LostFoundRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  LostFoundRemoteDatasource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  CollectionReference get _col => _firestore.collection('lost_found_posts');

  Stream<List<LostFoundPostModel>> watchPosts(LostFoundType type) {
    return _col
        .where('type', isEqualTo: type == LostFoundType.lost ? 'lost' : 'found')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LostFoundPostModel.fromFirestore(doc))
            .toList());
  }

  Stream<LostFoundPostModel?> watchPost(String postId) {
    return _col.doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return LostFoundPostModel.fromFirestore(doc);
    });
  }

  Future<List<LostFoundPostModel>> getOppositeTypePosts(
      LostFoundType type, String species) async {
    final oppositeType = type == LostFoundType.lost ? 'found' : 'lost';
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final snap = await _col
        .where('type', isEqualTo: oppositeType)
        .where('species', isEqualTo: species)
        .where('status', isEqualTo: 'active')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .limit(10)
        .get();
    return snap.docs
        .map((doc) => LostFoundPostModel.fromFirestore(doc))
        .toList();
  }

  Future<List<LostFoundPostModel>> getAllOppositeTypePosts(
      LostFoundType type) async {
    final oppositeType = type == LostFoundType.lost ? 'found' : 'lost';
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final snap = await _col
        .where('type', isEqualTo: oppositeType)
        .where('status', isEqualTo: 'active')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .limit(20)
        .get();
    return snap.docs
        .map((doc) => LostFoundPostModel.fromFirestore(doc))
        .toList();
  }

  Future<String> createPost(Map<String, dynamic> data) async {
    final doc = await _col.add(data);
    return doc.id;
  }

  Future<void> updateMatchingStatus(String postId, MatchingStatus status) async {
    final value = status == MatchingStatus.searching
        ? 'searching'
        : status == MatchingStatus.done
            ? 'done'
            : 'pending';
    await _col.doc(postId).update({'matchingStatus': value});
  }

  Future<void> addMatch(String postId, Map<String, dynamic> match) async {
    await _col.doc(postId).update({
      'matches': FieldValue.arrayUnion([match]),
    });
  }

  Future<void> markResolved(String postId) async {
    await _col.doc(postId).update({'status': 'resolved'});
  }

  Future<String> uploadImage(String postId, XFile file) async {
    final ref = _storage.ref().child('lost_found_images/$postId');
    await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
