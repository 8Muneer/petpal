import 'package:flutter/material.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';

/// Legacy wrapper — delegates to [AppScaffold].
class PetPalScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;

  const PetPalScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(body: body, bottomNavigationBar: bottomNavigationBar);
  }
}
