import 'dart:math';

/// Utility class for handling booking ID formatting and generation
class BookingIdUtils {
  static final Random _random = Random();

  /// Generate a booking ID with prefix 10000 followed by 6 random digits
  /// Format: 10000XXXXXX (where XXXXXX are random digits 0-9)
  static String generateBookingId() {
    // Generate 6 random digits
    final randomDigits = List.generate(6, (index) => _random.nextInt(10));
    final randomString = randomDigits.join('');

    // Combine with prefix
    return '10000$randomString';
  }

  /// Format an existing booking ID to display format
  /// If the ID is already in the correct format, return as-is
  /// Otherwise, generate a new formatted ID
  static String formatBookingId(int backendBookingId) {
    // Display the exact backend-provided booking ID without transformation
    return backendBookingId.toString();
  }

  /// Check if a booking ID is in the correct format (10000XXXXXX)
  static bool isValidFormat(String bookingId) {
    if (bookingId.length != 11) return false;
    if (!bookingId.startsWith('10000')) return false;

    // Check if the last 6 characters are all digits
    final lastSix = bookingId.substring(5);
    return lastSix.split('').every((char) => int.tryParse(char) != null);
  }

  /// Extract the random part from a formatted booking ID
  static String extractRandomPart(String bookingId) {
    if (!isValidFormat(bookingId)) return '';
    return bookingId.substring(5); // Return the last 6 digits
  }

  /// Get a short version of the booking ID for display (last 4 digits)
  static String getShortBookingId(String bookingId) {
    if (!isValidFormat(bookingId)) return bookingId;
    return '...${bookingId.substring(7)}'; // Show last 4 digits
  }
}
