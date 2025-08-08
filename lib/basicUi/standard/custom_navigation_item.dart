import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/constants/navigation_pages.dart';
import 'package:id_ideal_wallet/provider/navigation_provider.dart';
import 'package:id_ideal_wallet/views/ausweis_view.dart';
import 'package:id_ideal_wallet/functions/util.dart';

class CustomNavigationItem extends StatelessWidget {
  final String text;
  final IconData activeIcon, inactiveIcon;
  final List<NavigationPage> activeIndices;
  final NavigationProvider navigator;

  const CustomNavigationItem(
      {super.key,
      required this.text,
      required this.activeIcon,
      required this.inactiveIcon,
      required this.activeIndices,
      required this.navigator});

  @override
  Widget build(BuildContext context) {
    bool active = activeIndices.contains(navigator.activeIndex);
    return InkWell(
      onTap: () {
        // Special handling for ID Card (ausweis) to open as a new full-screen view
        if (activeIndices.contains(NavigationPage.ausweis)) {
          navigateClassic(const AusweisView());
        } else {
          navigator.changePage(activeIndices);
        }
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          active ? activeIcon : inactiveIcon,
          size: 32,
          color: Colors.black,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]),
    );
  }
}
