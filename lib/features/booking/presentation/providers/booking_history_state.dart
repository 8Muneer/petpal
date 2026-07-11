import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';

/// Mirrors feed_state.dart's FeedState — same cursor-pagination shape,
/// applied to booking history instead of feed posts.
class BookingHistoryState {
  final List<BookingRequest> bookings;
  final bool hasMore;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDoc;

  const BookingHistoryState({
    required this.bookings,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.lastDoc,
  });

  BookingHistoryState copyWith({
    List<BookingRequest>? bookings,
    bool? hasMore,
    bool? isLoadingMore,
    DocumentSnapshot? lastDoc,
  }) {
    return BookingHistoryState(
      bookings: bookings ?? this.bookings,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}
