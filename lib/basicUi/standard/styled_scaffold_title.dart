import 'package:flutter/material.dart';

class StyledScaffoldTitle extends StatelessWidget {
  const StyledScaffoldTitle(
      {super.key,
      required this.title,
      required this.child,
      this.currentlyActive,
      this.footerButtons,
      this.appBarActions,
      this.fab,
      this.useBackSwipe = true,
      this.leftTitle});

  final dynamic title;
  final String? leftTitle;
  final Widget child;
  final int? currentlyActive;
  final FloatingActionButton? fab;
  final List<Widget>? footerButtons;
  final List<Widget>? appBarActions;
  final bool useBackSwipe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: leftTitle == null,
        automaticallyImplyLeading: false,
        title: leftTitle != null 
            ? Row(
                children: [
                  Text(
                    leftTitle!,
                    style: Theme.of(context).primaryTextTheme.headlineLarge,
                  ),
                  const SizedBox(width: 20),
                  if (title is Widget) 
                    Flexible(
                      child: title,
                    ),
                ],
              )
            : title is String
                ? Text(
                    title,
                    style: Theme.of(context).primaryTextTheme.headlineLarge,
                  )
                : title,
        actions: appBarActions,
      ),
      body: Container(
          margin: const EdgeInsets.only(left: 10, right: 10, top: 0),
          child: child),
      persistentFooterButtons: footerButtons,
      floatingActionButton: fab,
    );
  }
}
