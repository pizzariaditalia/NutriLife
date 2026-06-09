import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImgBbService {
  // 📥 CADASTRE SUA CHAVE GRATUITA EM: https://api.imgbb.com/
  static const String _apiKey = '97948f4e2233a19c69feeeec36bf9419';

  static Future<String?> uploadImage(XFile file) async {
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey');
    
    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      
      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);
        // Retorna a URL direta da imagem hospedada
        return jsonResponse['data']['url'] as String;
      }
    } catch (e) {
      print('Erro ao fazer upload para o ImgBB: $e');
    }
    return null;
  }
}
