import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/widgets/rush_hour_dialog_handler.dart';

class RushHourDialog extends StatefulWidget {
  const RushHourDialog({super.key});

  @override
  State<RushHourDialog> createState() => _RushHourDialogState();
}

class _RushHourDialogState extends State<RushHourDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<RushHourPage> _pages = [
    RushHourPage(
      title: 'Rush Hour Alert',
      icon: Icons.access_time,
      description:
          'Many passengers are commuting now. It may take some time to find a driver.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], isDarkMode);
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildDotIndicator(index, isDarkMode),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CC58),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Okay',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(RushHourPage page, bool isDarkMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          page.icon,
          size: 80,
          color: const Color(0xFF00CC58),
        ),
        const SizedBox(height: 24),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          page.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            color:
                isDarkMode ? const Color(0xFFDEDEDE) : const Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }

  Widget _buildDotIndicator(int index, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? const Color(0xFF00CC58)
            : (isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFD3D3D3)),
      ),
    );
  }
}
