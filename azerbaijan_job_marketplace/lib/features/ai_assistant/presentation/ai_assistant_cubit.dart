import '../../../features/jobs/data/models/job_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/voice_service.dart';
import '../data/ai_profile_service.dart';
import '../data/ai_job_search_service.dart';

enum AiAssistantStatus { idle, listening, thinking, speaking }

class AiMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<JobModel>? jobs; // Payload to show interactive job cards

  AiMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.jobs,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiAssistantState {
  final AiAssistantStatus status;
  final List<AiMessage> messages;
  final String partialText; // Partial speech result

  const AiAssistantState({
    this.status = AiAssistantStatus.idle,
    this.messages = const [],
    this.partialText = '',
  });

  AiAssistantState copyWith({
    AiAssistantStatus? status,
    List<AiMessage>? messages,
    String? partialText,
  }) {
    return AiAssistantState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      partialText: partialText ?? this.partialText,
    );
  }
}

class AiAssistantCubit extends Cubit<AiAssistantState> {
  final AiService _aiService = AiService();
  final VoiceService _voiceService = VoiceService();
  final AiProfileService _profileService = AiProfileService();
  final AiJobSearchService _jobSearchService = AiJobSearchService();
  bool _hasGreeted = false;

  AiAssistantCubit() : super(const AiAssistantState());

  VoiceService get voiceService => _voiceService;

  /// AI popup ilk açılanda salamlama mesajı
  Future<void> greet() async {
    if (_hasGreeted) return;
    _hasGreeted = true;

    const greeting = 'Salam! Mən İşçi AI. Sənə bu gün necə kömək edə bilərəm?';
    
    final messages = List<AiMessage>.from(state.messages)
      ..add(AiMessage(text: greeting, isUser: false));
    
    emit(state.copyWith(
      messages: messages,
      status: AiAssistantStatus.speaking,
    ));

    try {
      await _voiceService.initialize();
      debugPrint('AiAssistantCubit: VoiceService initialized, starting to speak greeting');
      await _voiceService.speak(greeting);
      debugPrint('AiAssistantCubit: Greeting spoken');
    } catch (e, stackTrace) {
      debugPrint('AiAssistantCubit: Error in greet: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    // Wait for TTS to finish
    await Future.delayed(const Duration(seconds: 3));
    emit(state.copyWith(status: AiAssistantStatus.idle));
  }

  /// Mikrofondan dinləməyə başla
  Future<void> startListening() async {
    if (state.status == AiAssistantStatus.speaking) {
      await _voiceService.stopSpeaking();
    }

    emit(state.copyWith(status: AiAssistantStatus.listening, partialText: ''));
    
    await _voiceService.startListening((recognizedText) {
      if (recognizedText.isNotEmpty) {
        _processUserInput(recognizedText);
      } else {
        emit(state.copyWith(status: AiAssistantStatus.idle));
      }
    });
  }

  /// Dinləməni dayandır
  Future<void> stopListening() async {
    await _voiceService.stopListening();
    emit(state.copyWith(status: AiAssistantStatus.idle));
  }

  /// İstifadəçi mesajını yaz (text input)
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _processUserInput(text.trim());
  }

  /// İstifadəçi mesajını emal et
  Future<void> _processUserInput(String userText) async {
    // Add user message
    final messages = List<AiMessage>.from(state.messages)
      ..add(AiMessage(text: userText, isUser: true));
    
    emit(state.copyWith(
      messages: messages,
      status: AiAssistantStatus.thinking,
      partialText: '',
    ));

    try {
      // Get user profile for context
      final profileSummary = await _profileService.getProfileSummary();
      
      // Send to AI
      String aiResponse = await _aiService.sendMessage(
        userText,
        userProfileJson: profileSummary,
      );

      // Handle special commands in AI response
      final aiMessage = await _handleSpecialCommands(aiResponse);

      // Add AI response
      final updatedMessages = List<AiMessage>.from(state.messages)
        ..add(aiMessage);

      emit(state.copyWith(
        messages: updatedMessages,
        status: AiAssistantStatus.speaking,
      ));

      // Speak the response
      debugPrint('AiAssistantCubit: Starting to speak AI response');
      await _voiceService.speak(aiMessage.text);
      debugPrint('AiAssistantCubit: AI response spoken');
      
      // Wait then return to idle
      await _waitForSpeechDone();
      emit(state.copyWith(status: AiAssistantStatus.idle));
    } catch (e) {
      final errorMsg = 'Bağışlayın, bir xəta baş verdi. Zəhmət olmasa yenidən cəhd edin.';
      final updatedMessages = List<AiMessage>.from(state.messages)
        ..add(AiMessage(text: errorMsg, isUser: false));
      emit(state.copyWith(messages: updatedMessages, status: AiAssistantStatus.idle));
    }
  }

  /// AI cavabında xüsusi komandaları emal et
  Future<AiMessage> _handleSpecialCommands(String response) async {
    // Profile update command
    if (response.contains('[PROFILE_UPDATE]') && response.contains('[/PROFILE_UPDATE]')) {
      try {
        final jsonStr = response
            .split('[PROFILE_UPDATE]')[1]
            .split('[/PROFILE_UPDATE]')[0]
            .trim();
        
        // Clean markdown code blocks if present
        final cleanJson = jsonStr
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final profileData = json.decode(cleanJson) as Map<String, dynamic>;
        final success = await _profileService.updateProfileFromAi(profileData);
        
        if (success) {
          // Remove the JSON part from visible response
          response = response.split('[PROFILE_UPDATE]')[0].trim();
          if (response.isEmpty) {
            response = 'Profilin uğurla dolduruldu! İstəsən Profil səhifəsinə gedərək daha detallı düzəlişlər edə bilərsən.';
          }
        }
      } catch (e) {
        debugPrint('Profile update error: $e');
      }
      return AiMessage(text: response, isUser: false);
    }

    // Job search command
    if (response.contains('[JOB_SEARCH]') && response.contains('[/JOB_SEARCH]')) {
      try {
        final jsonStr = response
            .split('[JOB_SEARCH]')[1]
            .split('[/JOB_SEARCH]')[0]
            .trim();
        
        final cleanJson = jsonStr
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final searchData = json.decode(cleanJson) as Map<String, dynamic>;
        final query = searchData['query'] as String?;
        final limit = searchData['limit'] is int ? searchData['limit'] as int : 5;
        final sortBy = (searchData['sortBy'] as String?) ?? 'relevance';
        final ignoreProfile = searchData['ignoreProfile'] == true;
        
        final profile = await _profileService.getUserProfile();
        final jobs = await _jobSearchService.searchJobsForProfile(profile, query: query, limit: limit, sortBy: sortBy, ignoreProfile: ignoreProfile);
        
        if (jobs.isEmpty) {
          final emptyResponse = await _aiService.sendMessage(
            'Təəssüf ki, istifadəçinin profilinə və ya axtarışına tam uyğun iş tapa bilmədim. Bunu istifadəçiyə bildir və başqa axtarış təklif et.',
          );
          return AiMessage(text: emptyResponse, isUser: false);
        } else {
           final successResponse = await _aiService.sendMessage(
             'İstifadəçiyə uyğun işlər tapıldı. İndi ona həvəsləndirici bir cümlə yaz və de ki, aşağıdakı kartlardan fərqli işlərə baxa və müraciət edə bilər.',
           );
           return AiMessage(text: successResponse, isUser: false, jobs: jobs);
        }
      } catch (e) {
        debugPrint('Job search error: $e');
        return AiMessage(text: 'İş axtarışında xəta baş verdi. Zəhmət olmasa yenidən cəhd edin.', isUser: false);
      }
    }

    return AiMessage(text: response, isUser: false);
  }

  Future<void> _waitForSpeechDone() async {
    int maxWait = 60; // max 60 seconds
    while (_voiceService.isSpeaking && maxWait > 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      maxWait--;
    }
  }

  /// Söhbəti sıfırla
  void resetConversation() {
    _aiService.resetChat();
    _hasGreeted = false;
    emit(const AiAssistantState());
  }

  @override
  Future<void> close() {
    _voiceService.dispose();
    return super.close();
  }
}
