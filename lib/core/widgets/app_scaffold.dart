import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// Unified app scaffold — clean flat background, no decorative blobs.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = false,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Pill height (72) + bottom gap (12) = 84 dp clearance above the system bar.
    // Injecting this into MediaQuery means any primary scroll view gets the right
    // bottom padding automatically, without touching individual screens.
    final adjustedBody = bottomNavigationBar != null
        ? MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(
                bottom: mq.padding.bottom + 84,
              ),
            ),
            child: body,
          )
        : body;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor ?? AppColors.surfaceBase,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: adjustedBody,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
