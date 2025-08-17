import 'dart:convert';

String? getImageBase64(_selectedImage) {
  if (_selectedImage == null) return null;
  
  try {
    final bytes = _selectedImage!.readAsBytesSync();
    final extension = _selectedImage!.path.split('.').last.toLowerCase();
    
    String mimeType;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        mimeType = 'image/jpeg';
        break;
      case 'png':
        mimeType = 'image/png';
        break;
      case 'gif':
        mimeType = 'image/gif';
        break;
      default:
        mimeType = 'image/jpeg';
    }
    
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  } catch (e) {
    print('Error converting image to base64: $e');
    return null;
  }
}
