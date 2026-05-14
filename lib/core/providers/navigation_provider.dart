import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_provider.g.dart';

@riverpod
class HomeTabIndex extends _$HomeTabIndex {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}
