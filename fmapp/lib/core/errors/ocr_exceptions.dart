/// OCR-specific exceptions for the fmapp application
class OCRException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const OCRException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'OCRException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when image file is invalid or corrupted
class InvalidImageException extends OCRException {
  const InvalidImageException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception thrown when OCR processing fails
class OCRProcessingException extends OCRException {
  const OCRProcessingException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception thrown when text parsing fails or returns ambiguous results
class TextParsingException extends OCRException {
  final String rawText;
  final double confidence;

  const TextParsingException(
    String message,
    this.rawText,
    this.confidence, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);
}

/// Exception thrown when file access fails
class FileAccessException extends OCRException {
  final String filePath;

  const FileAccessException(String message, this.filePath, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception thrown when offline processing fails
class OfflineProcessingException extends OCRException {
  const OfflineProcessingException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception thrown when unsupported file format is provided
class UnsupportedFormatException extends OCRException {
  final String format;

  const UnsupportedFormatException(String message, this.format, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Exception thrown when ML Kit service is unavailable
class MLKitUnavailableException extends OCRException {
  const MLKitUnavailableException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}