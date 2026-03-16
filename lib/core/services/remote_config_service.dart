import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Parameter keys
  static const String _keyOpenRouterApiKey = 'openrouter_api_key';
  static const String _keyAiModelId = 'ai_model_id';
  static const String _keyAiModelName = 'ai_model_name';
  static const String _keyAiBaseUrl = 'ai_api_base_url';
  static const String _keyAzureTtsApiKey = 'azure_tts_api_key';
  static const String _keyAzureTtsRegion = 'azure_tts_region';

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 1), // Test üçün tez-tez yoxla
      ));

      // Default dəyərlər (əgər internet yoxdursa və ya config tapılmasa)
      await _remoteConfig.setDefaults({
        _keyOpenRouterApiKey: '',
        _keyAiModelId: 'google/gemini-flash-1.5-8b',
        _keyAiModelName: 'Google Gemini 3 Flash',
        // Base URL artıq avtomatik təyin edilir, amma yenə də default olaraq boş qoyuruq
        _keyAiBaseUrl: '', 
        _keyAzureTtsApiKey: '',
        _keyAzureTtsRegion: 'eastus',
      });

      // Yeni config yüklə və aktivləşdir
      await _remoteConfig.fetchAndActivate();
      
      debugPrint('Remote Config initialized successfully');
      debugPrint('AI Model ID from Remote Config: ${getAiModelId()}');
    } catch (e) {
      debugPrint('Failed to initialize Remote Config: $e');
    }
  }

  // Getters
  String get openRouterApiKey {
    try {
      return _remoteConfig.getString(_keyOpenRouterApiKey);
    } catch (e) {
      debugPrint('Error getting $_keyOpenRouterApiKey: $e');
      return '';
    }
  }
  
  String getAiModelId() {
    try {
      return _remoteConfig.getString(_keyAiModelId);
    } catch (e) {
      debugPrint('Error getting $_keyAiModelId: $e');
      return 'google/gemini-flash-1.5-8b'; // Fallback
    }
  }

  String getAiModelName() {
    try {
      return _remoteConfig.getString(_keyAiModelName);
    } catch (e) {
      return 'Google Gemini 3 Flash';
    }
  }

  String getAiBaseUrl() {
    try {
      return _remoteConfig.getString(_keyAiBaseUrl);
    } catch (e) {
      return '';
    }
  }

  String getAzureTtsApiKey() {
    try {
      return _remoteConfig.getString(_keyAzureTtsApiKey);
    } catch (e) {
      return '';
    }
  }

  String getAzureTtsRegion() {
    try {
      return _remoteConfig.getString(_keyAzureTtsRegion);
    } catch (e) {
      return 'eastus';
    }
  }
}
