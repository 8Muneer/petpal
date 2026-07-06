import 'package:flutter/material.dart';

import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/features/home/presentation/widgets/provider_services_tab.dart';

/// "My Services" as a real pushed page.
///
/// Previously this content was swapped into the provider home shell's body
/// (an in-place overlay), so it didn't behave like a page: no back
/// navigation, and the bottom tabs stayed visible underneath. The profile
/// menu now pushes this route instead.
class ProviderMyServicesScreen extends StatelessWidget {
  const ProviderMyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: ProviderServicesTab(standalone: true),
      ),
    );
  }
}
