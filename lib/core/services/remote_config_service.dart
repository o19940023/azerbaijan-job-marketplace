import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;

  // Parameter keys
  static const String _keyOpenRouterApiKey = 'openrouter_api_key';
  static const String _keyAiModelId = 'ai_model_id';
  static const String _keyAiModelName = 'ai_model_name';
  static const String _keyAiBaseUrl = 'ai_api_base_url';
  static const String _keyAzureTtsApiKey = 'azure_tts_api_key';
  static const String _keyAzureTtsRegion = 'azure_tts_region';
  static const String _keyGitHubApiKey = 'github_api_key';
  static const String _keyMinAppVersion = 'min_app_version';
  static const String _keyLatestAppVersion = 'latest_app_version';
  static const String _keyAndroidStoreUrl = 'android_store_url';
  static const String _keyIosStoreUrl = 'ios_store_url';

  Future<void> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5), // Hər 5 dəqiqədən bir yoxla
      ));

      // Default dəyərlər (əgər internet yoxdursa və ya config tapılmasa)
      await _remoteConfig!.setDefaults({
        _keyOpenRouterApiKey: '',
        _keyAiModelId: 'google/gemini-flash-1.5-8b',
        _keyAiModelName: 'Google Gemini 3 Flash',
        _keyAiBaseUrl: '', 
        _keyAzureTtsApiKey: '',
        _keyAzureTtsRegion: 'eastus',
        _keyGitHubApiKey: '',
        _keyMinAppVersion: '1.0.0',
        _keyLatestAppVersion: '1.0.0',
        _keyAndroidStoreUrl: 'https://play.google.com/store/apps/details?id=com.is.tap',
        _keyIosStoreUrl: 'https://apps.apple.com/app/id6742566101',
      });

      // Yeni config yüklə və aktivləşdir
      await _remoteConfig!.fetchAndActivate();
      
      debugPrint('Remote Config initialized successfully');
      debugPrint('AI Model ID from Remote Config: ${getAiModelId()}');
    } catch (e) {
      debugPrint('Failed to initialize Remote Config: $e');
      _remoteConfig = null; // Ensure it's null if init failed
    }
  }

  String _getString(String key, {String defaultValue = ''}) {
    try {
      if (_remoteConfig == null) {
        // Try to get instance lazily if it wasn't initialized yet
        try {
           _remoteConfig = FirebaseRemoteConfig.instance;
        } catch (_) {
           return defaultValue;
        }
      }
      return _remoteConfig!.getString(key);
    } catch (e) {
      debugPrint('Error getting $key: $e');
      return defaultValue;
    }
  }

  // Getters
  String get openRouterApiKey => _getString(_keyOpenRouterApiKey);
  
  String getAiModelId() => _getString(_keyAiModelId, defaultValue: 'google/gemini-flash-1.5-8b');

  String getAiModelName() => _getString(_keyAiModelName, defaultValue: 'Google Gemini 3 Flash');

  String getAiBaseUrl() => _getString(_keyAiBaseUrl);

  String getAzureTtsApiKey() => _getString(_keyAzureTtsApiKey);

  String getAzureTtsRegion() => _getString(_keyAzureTtsRegion, defaultValue: 'eastus');

  String getGitHubApiKey() => _getString(_keyGitHubApiKey);

  String getMinAppVersion() => _getString(_keyMinAppVersion, defaultValue: '1.0.0');

  String getLatestAppVersion() => _getString(_keyLatestAppVersion, defaultValue: '1.0.0');

  String getAndroidStoreUrl() => _getString(_keyAndroidStoreUrl, defaultValue: 'https://play.google.com/store/apps/details?id=com.is.tap');

  String getIosStoreUrl() => _getString(_keyIosStoreUrl, defaultValue: 'https://apps.apple.com/app/id6742566101');
}
