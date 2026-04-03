import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../home/views/home_view.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        if (!vm.initialized || vm.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!vm.isAuthenticated) {
          return const AuthScreen();
        }

        return const HomeView();
      },
    );
  }
}
