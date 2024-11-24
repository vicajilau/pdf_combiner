import 'package:flutter/material.dart';

/// Widget to display text that can be copied to the clipboard when tapped
class CopyableText extends StatelessWidget {
  /// Text to be displayed
  final String text;

  /// Custom text style, with a default value of font size 14
  final TextStyle textStyle;

  /// Callback function to define the action when text is tapped (e.g., copying to clipboard)
  final VoidCallback onCopy;

  /// Constructor to initialize the widget with required parameters
  const CopyableText({
    super.key,

    /// Key used to identify the widget in the widget tree (optional)
    required this.text,

    /// The text to display
    required this.onCopy,

    /// Callback function to trigger on tap
    this.textStyle = const TextStyle(fontSize: 14),

    /// Default text style with font size 14
  });

  @override
  Widget build(BuildContext context) {
    /// GestureDetector listens for tap events on the text
    return GestureDetector(
      onTap: onCopy,

      /// Trigger the onCopy callback when the text is tapped
      child: Text(
        text,

        /// Display the provided text
        style: textStyle,

        /// Apply the specified text style
      ),
    );
  }
}
