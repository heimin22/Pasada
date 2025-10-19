import 'package:flutter/material.dart';

class ResponsiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final MainAxisAlignment actionsAlignment;
  final EdgeInsets? contentPadding;

  const ResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.actionsAlignment = MainAxisAlignment.end,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate responsive values
    final titleFontSize = screenSize.width * 0.06;
    final padding = contentPadding ?? EdgeInsets.all(screenSize.width * 0.05);

    return Dialog(
      backgroundColor:
          isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenSize.width * 0.03),
        side: BorderSide(
          color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.05,
        vertical: screenSize.height * 0.03,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: double.infinity,
          maxHeight: screenSize.height * 0.5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        fontSize: titleFontSize,
                        color: isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF121212),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 1,
                      color: isDarkMode
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212),
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: padding,
                child: content,
              ),
              if (actions != null)
                Padding(
                  padding: padding,
                  child: Row(
                    mainAxisAlignment: actionsAlignment,
                    children: [
                      for (int i = 0; i < actions!.length; i++) ...[
                        Expanded(child: actions![i]),
                        if (i < actions!.length - 1)
                          SizedBox(width: screenSize.width * 0.02),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
