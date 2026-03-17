import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/sidebar/sidebar_cubit.dart';
import '../../widgets/sidebar/app_sidebar.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Auto-collapse sidebar when width < 900
        final sidebarCubit = context.read<SidebarCubit>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          sidebarCubit.setCollapsed(constraints.maxWidth < 900);
        });

        return Scaffold(
          body: Row(
            children: [
              const AppSidebar(),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
