import 'package:flutter/material.dart';

class AlertSequenceDialog extends StatefulWidget {
  final List<Widget> pages;
  const AlertSequenceDialog({super.key, required this.pages});

  @override
  _AlertSequenceDialogState createState() => _AlertSequenceDialogState();
}

class _AlertSequenceDialogState extends State<AlertSequenceDialog> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate responsive values
    final dialogPadding = screenSize.width * 0.06; // 6% of screen width
    final contentHeight = screenSize.height * 0.3; // 30% of screen height
    final borderRadius = screenSize.width * 0.04; // 4% of screen width
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: screenSize.width * 0.06, // 6% of screen width
      vertical: screenSize.height * 0.015, // 1.5% of screen height
    );
    final buttonFontSize = screenSize.width * 0.04; // 4% of screen width
    final indicatorSize = screenSize.width * 0.03; // 3% of screen width
    final spacing = screenSize.height * 0.02; // 2% of screen height

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.05, // 5% margin on sides
        vertical: screenSize.height * 0.1, // 10% margin top/bottom
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.9, // Max 90% of screen width
          maxHeight: screenSize.height * 0.8, // Max 80% of screen height
        ),
        child: Container(
          padding: EdgeInsets.all(dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Swipeable page content
              SizedBox(
                height: contentHeight,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: widget.pages,
                ),
              ),
              SizedBox(height: spacing),
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.pages.length,
                  (index) => Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: indicatorSize * 0.3),
                    width: _currentPage == index
                        ? indicatorSize * 1.5
                        : indicatorSize,
                    height: _currentPage == index
                        ? indicatorSize * 1.5
                        : indicatorSize,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF00CC58)
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing * 1.2),
              // Navigation button
              ElevatedButton(
                onPressed: () {
                  if (_currentPage < widget.pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00CC58),
                  foregroundColor: Colors.white,
                  padding: buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(screenSize.width * 0.02),
                  ),
                ),
                child: Text(
                  _currentPage < widget.pages.length - 1 ? 'Next' : 'Okay po!',
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
