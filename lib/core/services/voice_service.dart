import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:azerbaijan_job_marketplace/core/services/remote_config_service.dart';

class VoiceService {
  // Azure Cognitive Services TTS - Ücretsiz tier (500K karakter/ay)
  // Azerbaycan dili: az-AZ-BabekNeural (erkek, yüksek kalite)
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _stt = stt.SpeechToText();
  
  bool _isSpeaking = false;
  bool _isListening = false;
  
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  
  final _listeningController = StreamController<bool>.broadcast();
  final _speakingController = StreamController<bool>.broadcast();
  
  Stream<bool> get listeningStream => _listeningController.stream;
  Stream<bool> get speakingStream => _speakingController.stream;

  Future<void> initialize() async {
    try {
      // Set audio mode for better playback
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);
      
      _audioPlayer.onPlayerComplete.listen((_) {
        debugPrint('VoiceService: Player completed');
        _isSpeaking = false;
        _speakingController.add(false);
      });
      
      _audioPlayer.onPlayerStateChanged.listen((state) {
        debugPrint('VoiceService: Player state changed to $state');
        if (state == PlayerState.playing) {
          _isSpeaking = true;
          _speakingController.add(true);
        } else if (state == PlayerState.completed || state == PlayerState.stopped) {
          _isSpeaking = false;
          _speakingController.add(false);
        }
      });
      
      debugPrint('VoiceService: initialized with Azure TTS (az-AZ-BabekNeural)');
    } catch (e, stackTrace) {
      debugPrint('VoiceService init error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> startListening(Function(String) onResult) async {
    try {
      final available = await _stt.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _listeningController.add(false);
          }
        },
        onError: (error) {
          debugPrint('STT Error: ${error.errorMsg}');
          _isListening = false;
          _listeningController.add(false);
        },
      );
      
      if (available) {
        _isListening = true;
        _listeningController.add(true);
        
        await _stt.listen(
          onResult: (result) {
            if (result.finalResult) {
              final text = result.recognizedWords;
              _isListening = false;
              _listeningController.add(false);
              onResult(text);
            }
          },
          localeId: 'az_AZ',
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        );
      } else {
        debugPrint('STT: Speech recognition not available');
        _isListening = false;
        _listeningController.add(false);
        onResult('');
      }
    } catch (e) {
      debugPrint('STT startListening error: $e');
      _isListening = false;
      _listeningController.add(false);
      onResult('');
    }
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (e) {
      debugPrint('STT stopListening error: $e');
    }
    _isListening = false;
    _listeningController.add(false);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    try {
      // Xüsusi simvolları və JSON bloklarını təmizlə
      String cleanText = text
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .replaceAll(RegExp(r'\{.*?\}', dotAll: true), '')
          .replaceAll(RegExp(r'```.*?```', dotAll: true), '')
          .replaceAll(RegExp(r'[*_#`]'), '')
          .replaceAll(RegExp(r'\n+'), ' ')
          .trim();
      
      if (cleanText.isEmpty) return;
      
      debugPrint('VoiceService: Speaking text: ${cleanText.substring(0, cleanText.length > 50 ? 50 : cleanText.length)}...');
      
      _isSpeaking = true;
      _speakingController.add(true);
      
      // Azure TTS - Ücretsiz, yüksek kalite
      final success = await _speakWithAzureTTS(cleanText);
      
      if (!success) {
        debugPrint('VoiceService: Azure TTS failed');
      }
      
      _isSpeaking = false;
      _speakingController.add(false);
      debugPrint('VoiceService: Speaking completed');
    } catch (e, stackTrace) {
      debugPrint('TTS speak error: $e');
      debugPrint('Stack trace: $stackTrace');
      _isSpeaking = false;
      _speakingController.add(false);
    }
  }

  Future<bool> _speakWithAzureTTS(String text) async {
    try {
      debugPrint('VoiceService: Using Azure TTS...');
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/tts_azure_${DateTime.now().millisecondsSinceEpoch}.mp3');
      
      // Azure TTS API Key - Priority: Remote Config > .env
      String azureApiKey = RemoteConfigService().getAzureTtsApiKey();
      if (azureApiKey.isEmpty) {
        azureApiKey = dotenv.env['AZURE_TTS_API_KEY'] ?? '';
      }

      String azureRegion = RemoteConfigService().getAzureTtsRegion();
      if (azureRegion.isEmpty || azureRegion == 'eastus') { // If default or empty, check .env
        azureRegion = dotenv.env['AZURE_TTS_REGION'] ?? 'eastus';
      }
      
      // Azure TTS SSML
      final ssml = '''
<speak version='1.0' xml:lang='az-AZ'>
  <voice name='az-AZ-BabekNeural'>
    <prosody rate='0%' pitch='0%'>
      $text
    </prosody>
  </voice>
</speak>
''';
      
      // Azure TTS endpoint with authentication
      final response = await http.post(
        Uri.parse('https://$azureRegion.api.cognitive.microsoft.com/sts/v1.0/issuetoken'),
        headers: {
          'Ocp-Apim-Subscription-Key': azureApiKey,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        debugPrint('Azure TTS: Failed to get token: ${response.statusCode}');
        debugPrint('Azure TTS: Region: $azureRegion');
        debugPrint('Azure TTS: API Key Length: ${azureApiKey.length}'); // Log length only for security
        return false;
      }
      
      final token = response.body;
      debugPrint('VoiceService: Azure token obtained');
      
      // Now make TTS request with token
      final ttsResponse = await http.post(
        Uri.parse('https://$azureRegion.tts.speech.microsoft.com/cognitiveservices/v1'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/ssml+xml',
          'X-Microsoft-OutputFormat': 'audio-24khz-48kbitrate-mono-mp3',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
        body: ssml,
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('VoiceService: Azure TTS response status: ${ttsResponse.statusCode}, bytes: ${ttsResponse.bodyBytes.length}');
      
      if (ttsResponse.statusCode == 200 && ttsResponse.bodyBytes.isNotEmpty) {
        await audioFile.writeAsBytes(ttsResponse.bodyBytes);
        debugPrint('VoiceService: Azure TTS audio saved: ${audioFile.path}');
        
        final completer = Completer<void>();
        late StreamSubscription sub;
        sub = _audioPlayer.onPlayerComplete.listen((_) {
          if (!completer.isCompleted) completer.complete();
          sub.cancel();
        });
        
        try {
          await _audioPlayer.play(DeviceFileSource(audioFile.path));
        } catch (e) {
          debugPrint('VoiceService: Failed to play from file, trying bytes: $e');
          await _audioPlayer.play(BytesSource(ttsResponse.bodyBytes));
        }
        
        await completer.future.timeout(
          const Duration(seconds: 60),
          onTimeout: () => sub.cancel(),
        );
        
        return true;
      } else {
        debugPrint('Azure TTS Error: ${ttsResponse.statusCode}');
        if (ttsResponse.statusCode == 401 || ttsResponse.statusCode == 403) {
          debugPrint('Azure TTS: Authentication failed. Please check API key.');
        }
        return false;
      }
    } catch (e) {
      debugPrint('Azure TTS Exception: $e');
      return false;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      _isSpeaking = false;
      _speakingController.add(false);
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('TTS stopSpeaking error: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _stt.stop();
    _listeningController.close();
    _speakingController.close();
  }
}
