enum PaperType { label, continuous }

abstract class PaperSize{
  final String name = '';
  // Paper width in mm
  final int width = 58;
  final int height = 0;
  final int characterLength = 0;
  final int lineLength = 0;
  final PaperType paperType = PaperType.continuous;
  final int maxImageWidth = 384;
}