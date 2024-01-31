import 'package:flutter/material.dart';
import 'package:inventool/utils/colors.dart';
import 'package:inventool/utils/app_theme.dart';

class NavigationCard extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  NavigationCard({required this.title, required this.onTap});

  @override
  _NavigationCardState createState() => _NavigationCardState();
}

class _NavigationCardState extends State<NavigationCard> {
  late Color cardBackgroundColor;
  late Color hoverColor;

  @override
  void initState() {
    super.initState();
    // Initial default values
    cardBackgroundColor = AppColors.blueGrey900;
    hoverColor = AppColors.blueGrey700;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setInitialColors();
  }

  void setInitialColors() {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      cardBackgroundColor = AppColors.blueGrey800;
      hoverColor = AppColors.blueGrey700;
    } else {
      cardBackgroundColor = AppColors.teal50;
      hoverColor = AppColors.teal100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => cardBackgroundColor = hoverColor),
          onExit: (_) => setState(() => setInitialColors()),
          child: SizedBox(
            height: 75,
            width: 300,
            child: Card(
              color: cardBackgroundColor,
              elevation: 3.0,
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    widget.title,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
