import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

/// Builds a monochrome QR image for thermal printing.
class ReceiptQrHelper {
  static img.Image generateQrImage(
    String data, {
    int size = 200,
  }) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;
    final pixelSize = (size / moduleCount).ceil().clamp(1, 16);
    final imageSize = moduleCount * pixelSize;
    final image = img.Image(imageSize, imageSize);
    image.fill(img.getColor(255, 255, 255));

    for (var y = 0; y < moduleCount; y++) {
      for (var x = 0; x < moduleCount; x++) {
        final isDark = qrImage.isDark(y, x);
        final color =
            isDark ? img.getColor(0, 0, 0) : img.getColor(255, 255, 255);
        for (var py = 0; py < pixelSize; py++) {
          for (var px = 0; px < pixelSize; px++) {
            image.setPixel(
              x * pixelSize + px,
              y * pixelSize + py,
              color,
            );
          }
        }
      }
    }

    return image;
  }
}
