import 'package:flutter/cupertino.dart';
import 'package:id_ideal_wallet/views/welcome_screen.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../provider/navigation_provider.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(builder: (context, navigator, child) {
      return navigator.showWelcome ? const WelcomeScreen() : const HomeScreen();
    });
  }
}
