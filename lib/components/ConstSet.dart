// VisibleCount

class ConstSet {
  static const double smallGap = 5.0;
  static const double mediumGap = 10.0;
  static const double largeGap = 20.0;
  static const double xlargeGap = 100.0;

  static const int visibleCount = 12;
  static const int limit = visibleCount - 2;
  static double screenHeight = 0;
  static double itemHeight = 0;

  static void setHeights(double value) {
    screenHeight = value;
    itemHeight = value / visibleCount;
  }
}
