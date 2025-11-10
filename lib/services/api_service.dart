import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:amical_club/constant.dart';

class ApiService {

  // Headers par défaut
  static Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Inscription
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? location,
    String? teamName,
    String? clubName,
    String? category,
    String? level,
    String? licenseNumber,
    String? experience,
    String? phone,
  }) async {
    try {
      final url = '${baseUrl}/register.php';
      print('Tentative de connexion à: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
          'location': location,
          'team_name': teamName,
          'club_name': clubName,
          'category': category,
          'level': level,
          'license_number': licenseNumber,
          'experience': experience,
          'phone': phone,
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Vérifier si la réponse est du JSON valide
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Erreur serveur: Le fichier PHP n\'est pas accessible. Vérifiez l\'URL: $url',
        };
      }

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de l\'inscription',
        };
      }
    } catch (e) {
      print('Erreur API: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Connexion
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = '${baseUrl}/login.php';
      print('🔄 ApiService.login: URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('📡 ApiService.login: Status Code: ${response.statusCode}');
      print('📡 ApiService.login: Response Body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ ApiService.login: Connexion réussie');
        print('📦 ApiService.login: Data: ${responseData['data']}');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la connexion',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Déconnexion
  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/logout.php'),
        headers: _getHeaders(token: token),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la déconnexion',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Vérifier un token
  static Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/verify_token.php'),
        headers: _getHeaders(token: token),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Token invalide',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Récupérer les détails d'une équipe
  static Future<Map<String, dynamic>> getTeam(String token, String teamId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/get_team.php?team_id=$teamId'),
        headers: _getHeaders(token: token),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la récupération de l\'équipe',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Mettre à jour une équipe
  static Future<Map<String, dynamic>> updateTeam({
    required String token,
    required String teamId,
    String? name,
    String? clubName,
    String? category,
    String? level,
    String? location,
    String? description,
    String? founded,
    String? homeStadium,
    String? achievements,
    String? logo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/update_team.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'team_id': teamId,
          'name': name,
          'club_name': clubName,
          'category': category,
          'level': level,
          'location': location,
          'description': description,
          'founded': founded,
          'home_stadium': homeStadium,
          'achievements': achievements,
          'logo': logo,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la mise à jour de l\'équipe',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Créer une nouvelle équipe
  static Future<Map<String, dynamic>> createTeam({
    required String token,
    required String name,
    String? clubName,
    String? category,
    String? level,
    String? location,
    String? description,
    String? founded,
    String? homeStadium,
    String? achievements,
    String? logo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/create_team.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'name': name,
          'club_name': clubName,
          'category': category,
          'level': level,
          'location': location,
          'description': description,
          'founded': founded,
          'home_stadium': homeStadium,
          'achievements': achievements,
          'logo': logo,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la création de l\'équipe',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Supprimer une équipe
  static Future<Map<String, dynamic>> deleteTeam({
    required String token,
    required String teamId,
  }) async {
    try {
      final url = '${baseUrl}/delete_team.php';
      print('🔄 ApiService.deleteTeam: URL: $url');
      print('🔄 ApiService.deleteTeam: teamId: $teamId');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(token: token),
        body: json.encode({
          'team_id': teamId,
        }),
      );

      print('📡 ApiService.deleteTeam: Status Code: ${response.statusCode}');
      print('📡 ApiService.deleteTeam: Response Body: ${response.body}');

      // Vérifier si la réponse est vide
      if (response.body.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Erreur serveur: Réponse vide du serveur (Status: ${response.statusCode})',
        };
      }

      // Vérifier si la réponse est du JSON valide
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Erreur serveur: Le fichier PHP n\'est pas accessible. Vérifiez l\'URL: $url',
        };
      }

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ ApiService.deleteTeam: Suppression réussie');
        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        print('❌ ApiService.deleteTeam: Erreur API: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la suppression',
        };
      }
    } catch (e) {
      print('❌ ApiService.deleteTeam: Exception: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Récupérer toutes les équipes (pour la recherche)
  static Future<Map<String, dynamic>> getAllTeams() async {
    try {
      final url = '${baseUrl}/get_all_teams.php';
      print('🔄 ApiService.getAllTeams: URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      print('📡 ApiService.getAllTeams: Status Code: ${response.statusCode}');
      print('📡 ApiService.getAllTeams: Response Body: ${response.body}');

      // Vérifier si la réponse est vide
      if (response.body.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Erreur serveur: Réponse vide du serveur (Status: ${response.statusCode})',
        };
      }

      // Vérifier si la réponse est du JSON valide
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Erreur serveur: Le fichier PHP n\'est pas accessible. Vérifiez l\'URL: $url',
        };
      }

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ ApiService.getAllTeams: ${responseData['data']?.length ?? 0} équipes récupérées');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la récupération des équipes',
        };
      }
    } catch (e) {
      print('❌ ApiService.getAllTeams: Exception: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Mettre à jour le profil du coach
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String location,
    required String licenseNumber,
    required String experience,
    String? avatar,
  }) async {
    try {
      final url = '${baseUrl}/update_profile.php';
      print('🔄 ApiService.updateProfile: URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(token: token),
        body: json.encode({
          'name': name,
          'location': location,
          'license_number': licenseNumber,
          'experience': experience,
          'avatar': avatar,
        }),
      );

      print('📡 ApiService.updateProfile: Status Code: ${response.statusCode}');
      print('📡 ApiService.updateProfile: Response Body: ${response.body}');

      // Vérifier si la réponse est vide
      if (response.body.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Erreur serveur: Réponse vide du serveur (Status: ${response.statusCode})',
        };
      }

      // Vérifier si la réponse est du JSON valide
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Erreur serveur: Le fichier PHP n\'est pas accessible. Vérifiez l\'URL: $url',
        };
      }

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ ApiService.updateProfile: Profil mis à jour');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } catch (e) {
      print('❌ ApiService.updateProfile: Exception: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Upload d'avatar
  static Future<Map<String, dynamic>> uploadAvatar({
    required String token,
    required File imageFile,
  }) async {
    try {
      final url = '${baseUrl}/upload_avatar.php';
      print('🔄 ApiService.uploadAvatar: URL: $url');
      print('📁 ApiService.uploadAvatar: Taille fichier: ${imageFile.lengthSync()} bytes');

      // Créer un multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_getHeaders(token: token));

      // Ajouter l'image avec le bon nom de fichier
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;
      print('📁 ApiService.uploadAvatar: Nom fichier: $fileName');

      final multipartFile = http.MultipartFile.fromBytes(
        'avatar',
        bytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      print('📤 ApiService.uploadAvatar: Envoi de la requête...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('📥 ApiService.uploadAvatar: Réponse reçue (${responseBody.length} caractères)');

      print('📡 ApiService.uploadAvatar: Status Code: ${response.statusCode}');
      print('📡 ApiService.uploadAvatar: Response Body: $responseBody');

      // Vérifier si la réponse est vide
      if (responseBody.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Erreur serveur: Réponse vide du serveur (Status: ${response.statusCode})',
        };
      }

      // Vérifier si la réponse est du JSON valide
      if (responseBody.trim().startsWith('<!DOCTYPE') ||
          responseBody.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Erreur serveur: Le fichier PHP n\'est pas accessible. Vérifiez l\'URL: $url',
        };
      }

      final Map<String, dynamic> responseData = json.decode(responseBody);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ ApiService.uploadAvatar: Avatar uploadé avec succès');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de l\'upload',
        };
      }
    } catch (e) {
      print('❌ ApiService.uploadAvatar: Exception: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Upload de logo d'équipe
  static Future<Map<String, dynamic>> uploadTeamLogo({
    required String token,
    required File imageFile,
    required String teamId,
  }) async {
    try {
      final url = '${baseUrl}/upload_team_logo.php';
      print('🔄 ApiService.uploadTeamLogo: URL: $url');
      print('📁 ApiService.uploadTeamLogo: Taille fichier: ${imageFile.lengthSync()} bytes');
      print('📁 ApiService.uploadTeamLogo: Team ID: $teamId');

      // Créer un multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_getHeaders(token: token));

      // Ajouter le team_id
      request.fields['team_id'] = teamId;

      // Ajouter l'image avec le bon nom de fichier
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;
      print('📁 ApiService.uploadTeamLogo: Nom fichier: $fileName');

      final multipartFile = http.MultipartFile.fromBytes(
        'logo',
        bytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      print('📤 ApiService.uploadTeamLogo: Envoi de la requête...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('📥 ApiService.uploadTeamLogo: Réponse reçue (${responseBody.length} caractères)');

      print('📡 ApiService.uploadTeamLogo: Status Code: ${response.statusCode}');
      print('📡 ApiService.uploadTeamLogo: Response Body: $responseBody');

      // Vérifier si la réponse est vide
      if (responseBody.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Erreur serveur: Réponse vide du serveur (Status: ${response.statusCode})',
        };
      }

      // Vérifier si la réponse est du JSON valide
      if (responseBody.trim().startsWith('<!DOCTYPE') ||
          responseBody.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Erreur serveur: Le fichier PHP n\'est pas accessible. Vérifiez l\'URL: $url',
        };
      }

      final Map<String, dynamic> responseData = json.decode(responseBody);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ ApiService.uploadTeamLogo: Logo uploadé avec succès');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de l\'upload',
        };
      }
    } catch (e) {
      print('❌ ApiService.uploadTeamLogo: Exception: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Créer un match
  static Future<Map<String, dynamic>> createMatch({
    required String token,
    required String teamId,
    required String date,
    required String time,
    required String location,
    required String category,
    String? level,
    String? gender,
    String? stadium,
    String? description,
    String? notes,
    List<String>? facilities,
    bool? autoValidation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/create_match.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'team_id': teamId,
          'date': date,
          'time': time,
          'location': location,
          'category': category,
          'level': level,
          'gender': gender,
          'stadium': stadium,
          'description': description,
          'notes': notes,
          'facilities': facilities,
          'auto_validation': autoValidation ?? false,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la création du match',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Récupérer tous les matchs
  static Future<Map<String, dynamic>> getMatches({
    required String token,
    String? category,
    String? level,
    String? gender,
    String? search,
    String? status = 'available',
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{
        if (category != null && category.isNotEmpty) 'category': category,
        if (level != null && level.isNotEmpty) 'level': level,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
        if (search != null && search.isNotEmpty) 'search': search,
        'status': status ?? 'available',
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
      };

      final uri = Uri.parse('${baseUrl}/get_matches.php').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders(token: token));

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la récupération des matchs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Récupérer les détails d'un match
  static Future<Map<String, dynamic>> getMatch({
    required String token,
    required String matchId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/get_match.php?id=$matchId'),
        headers: _getHeaders(token: token),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la récupération du match',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Faire une demande de match
  static Future<Map<String, dynamic>> requestMatch({
    required String token,
    required String matchId,
    required String teamId,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/request_match.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'match_id': matchId,
          'team_id': teamId,
          'message': message,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la demande de match',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Mettre à jour le score d'un match
  static Future<Map<String, dynamic>> updateMatchScore({
    required String token,
    required String matchId,
    required String homeScore,
    required String awayScore,
    required List<String> homeScorers,
    required List<String> awayScorers,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/update_match_score.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'match_id': matchId,
          'home_score': homeScore,
          'away_score': awayScore,
          'home_scorers': homeScorers,
          'away_scorers': awayScorers,
          'notes': notes,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la mise à jour du score',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Récupérer les matchs du coach connecté
  static Future<Map<String, dynamic>> getMyMatches({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/get_my_matches.php'),
        headers: _getHeaders(token: token),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la récupération des matchs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Modifier un match existant
  static Future<Map<String, dynamic>> updateMatch({
    required String token,
    required String matchId,
    required String teamId,
    required String date,
    required String time,
    required String location,
    required String category,
    String? level,
    String? gender,
    String? stadium,
    String? description,
    String? notes,
    List<String>? facilities,
    bool? autoValidation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/update_match.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'match_id': matchId,
          'team_id': teamId,
          'date': date,
          'time': time,
          'location': location,
          'category': category,
          'level': level,
          'gender': gender,
          'stadium': stadium,
          'description': description, // Pour la table amicalclub_teams
          'match_notes': notes, // Pour la table amicalclub_matches
          'facilities': facilities ?? [],
          'auto_validation': autoValidation,
        }),
      );

      print('🔍 DEBUG: Response status: ${response.statusCode}');
      print('🔍 DEBUG: Response body: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur',
        };
      }

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la mise à jour du match',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Supprimer un match
  static Future<Map<String, dynamic>> deleteMatch({
    required String token,
    required String matchId,
  }) async {
    try {
      print('🔍 DEBUG DELETE: Tentative suppression match ID: $matchId');
      
      final response = await http.post(
        Uri.parse('${baseUrl}/delete_match.php'), // Version corrigée
        headers: _getHeaders(token: token),
        body: json.encode({
          'match_id': matchId,
        }),
      );

      print('🔍 DEBUG DELETE: Response status: ${response.statusCode}');
      print('🔍 DEBUG DELETE: Response body: ${response.body}');

      if (response.body.isEmpty) {
        print('⚠️ DEBUG DELETE: Réponse vide du serveur');
        return {
          'success': false,
          'message': 'Réponse vide du serveur',
        };
      }

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ DEBUG DELETE: Suppression réussie');
        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        print('❌ DEBUG DELETE: Erreur API: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la suppression du match',
        };
      }
    } catch (e) {
      print('❌ DEBUG DELETE: Exception: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Récupérer les demandes de match (reçues ou envoyées)
  static Future<Map<String, dynamic>> getMatchRequests({
    required String token,
    String type = 'received', // 'received' ou 'sent'
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/get_match_requests.php?type=$type'),
        headers: _getHeaders(token: token),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la récupération des demandes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Répondre à une demande de match (accepter ou rejeter)
  static Future<Map<String, dynamic>> respondToMatchRequest({
    required String token,
    required String requestId,
    required String action, // 'accept' ou 'reject'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/respond_match_request.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'request_id': requestId,
          'action': action,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors du traitement de la demande',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Récupérer les matchs confirmés (en cours)
  static Future<Map<String, dynamic>> getConfirmedMatches({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/get_confirmed_matches.php'),
        headers: _getHeaders(token: token),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la récupération des matchs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Mettre à jour le résultat d'un match
  static Future<Map<String, dynamic>> updateMatchResult({
    required String token,
    required String matchId,
    required String score,
    required String result,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/update_match_result.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'match_id': matchId,
          'score': score,
          'result': result,
          'notes': notes,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Confirmer la fin d'un match (validation par les 2 équipes)
  static Future<Map<String, dynamic>> confirmMatchCompletion({
    required String token,
    required String matchId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/confirm_match_completion.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'match_id': matchId,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la confirmation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Ajouter les détails complets d'un match (après validation des 2 équipes)
  static Future<Map<String, dynamic>> addMatchDetails({
    required String token,
    required String matchId,
    required String score,
    required String result,
    List<Map<String, dynamic>>? homeScorers,
    List<Map<String, dynamic>>? awayScorers,
    String? manOfMatch,
    List<String>? yellowCards,
    List<String>? redCards,
    String? matchSummary,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/add_match_details.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'match_id': matchId,
          'score': score,
          'result': result,
          'home_scorers': homeScorers,
          'away_scorers': awayScorers,
          'man_of_match': manOfMatch,
          'yellow_cards': yellowCards,
          'red_cards': redCards,
          'match_summary': matchSummary,
          'notes': notes,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de l\'ajout des détails',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Récupérer les matchs terminés (avec détails complets)
  static Future<Map<String, dynamic>> getCompletedMatches({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/get_completed_matches.php'),
        headers: _getHeaders(token: token),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'matches': [],
      };
    }
  }

  // Récupérer une équipe publique (n'importe quelle équipe)
  static Future<Map<String, dynamic>> getPublicTeam({
    required String token,
    required String teamId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/get_public_team.php?team_id=$teamId'),
        headers: _getHeaders(token: token),
      );
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'data': null,
      };
    }
  }

  // ==================== CHAT APIs ====================

  // Récupérer les conversations
  static Future<Map<String, dynamic>> getConversations({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_conversations.php'),
        headers: _getHeaders(token: token),
      );
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'conversations': [],
      };
    }
  }

  // Récupérer les messages d'une conversation
  static Future<Map<String, dynamic>> getMessages({
    required String token,
    required String conversationId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/get_messages.php?conversation_id=$conversationId&page=$page&limit=$limit'),
        headers: _getHeaders(token: token),
      );
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'messages': [],
      };
    }
  }

  // Envoyer un message
  static Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String receiverId,
    required String message,
    String messageType = 'text',
    String? fileUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/send_message.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'receiver_id': receiverId,
          'message': message,
          'message_type': messageType,
          'file_url': fileUrl,
        }),
      );
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'data': null,
      };
    }
  }

  // Marquer les messages comme lus
  static Future<Map<String, dynamic>> markMessagesRead({
    required String token,
    String? conversationId,
    List<String>? messageIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/mark_messages_read.php'),
        headers: _getHeaders(token: token),
        body: json.encode({
          'conversation_id': conversationId,
          'message_ids': messageIds,
        }),
      );
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  // Récupérer les notifications de chat
  static Future<Map<String, dynamic>> getChatNotifications({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/get_chat_notifications.php'),
        headers: _getHeaders(token: token),
      );
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'notifications': [],
        'unread_count': 0,
      };
    }
  }
}

