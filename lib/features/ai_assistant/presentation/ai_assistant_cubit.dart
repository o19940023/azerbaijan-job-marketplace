import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/jobs/data/models/job_model.dart';
import '../../../core/services/voice_service.dart';
import '../data/ai_profile_service.dart';
import '../data/ai_job_search_service.dart';
import '../data/services/ai_service.dart';

// ─────────────────────────────────────────────────
//  ENUMS & MODELS
// ─────────────────────────────────────────────────

enum AiAssistantStatus { idle, listening, thinking, speaking }

/// Chat message model — can carry job cards
class AiMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<JobModel>? jobs;
  final AiMessageType type;

  AiMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.jobs,
    this.type = AiMessageType.normal,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum AiMessageType {
  normal,
  profileUpdated,
  jobResults,
  error,
  tip,
}

// ─────────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────────

class AiAssistantState {
  final AiAssistantStatus status;
  final List<AiMessage> messages;
  final String partialText;
  final bool showProfileUpdatedNotification;
  final UserRole userRole;
  final bool isTyping; // Show typing indicator while AI thinks

  const AiAssistantState({
    this.status = AiAssistantStatus.idle,
    this.messages = const [],
    this.partialText = '',
    this.showProfileUpdatedNotification = false,
    this.userRole = UserRole.unknown,
    this.isTyping = false,
  });

  AiAssistantState copyWith({
    AiAssistantStatus? status,
    List<AiMessage>? messages,
    String? partialText,
    bool? showProfileUpdatedNotification,
    UserRole? userRole,
    bool? isTyping,
  }) {
    return AiAssistantState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      partialText: partialText ?? this.partialText,
      showProfileUpdatedNotification:
          showProfileUpdatedNotification ?? this.showProfileUpdatedNotification,
      userRole: userRole ?? this.userRole,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

// ─────────────────────────────────────────────────
//  CUBIT
// ─────────────────────────────────────────────────

class AiAssistantCubit extends Cubit<AiAssistantState> {
  final AiService _aiService = AiService();
  final VoiceService _voiceService = VoiceService();
  final AiProfileService _profileService = AiProfileService();
  final AiJobSearchService _jobSearchService = AiJobSearchService();

  bool _hasGreeted = false;

  AiAssistantCubit() : super(const AiAssistantState());

  VoiceService get voiceService => _voiceService;

  // ─────────────────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────────────────

  /// Reset the whole conversation and re-greet
  Future<void> resetConversation() async {
    await _voiceService.stopSpeaking();
    await _voiceService.stopListening();

    _aiService.resetChat();
    _hasGreeted = false;

    emit(const AiAssistantState());
    greet();
  }

  /// Initial greeting when AI panel opens
  Future<void> greet() async {
    if (_hasGreeted) return;
    _hasGreeted = true;

    // Personalized greeting based on profile
    String greeting = await _buildGreeting();

    final messages = List<AiMessage>.from(state.messages)
      ..add(AiMessage(text: greeting, isUser: false));

    emit(state.copyWith(
      messages: messages,
      status: AiAssistantStatus.speaking,
    ));

    try {
      await _voiceService.initialize();
      await _voiceService.speak(greeting);
    } catch (e) {
      debugPrint('AiAssistantCubit greet error: $e');
    }

    await Future.delayed(const Duration(seconds: 3));
    emit(state.copyWith(status: AiAssistantStatus.idle));
  }

  /// Build a personalized greeting from user profile
  Future<String> _buildGreeting() async {
    try {
      final profile = await _profileService.getUserProfile();
      final name = (profile?['fullName'] ?? '').toString().trim();
      final profession = (profile?['profession'] ?? '').toString().trim();

      if (name.isNotEmpty && profession.isNotEmpty) {
        return 'Salam, $name! 👋 Səninlə yenidən görüşdüm. $profession olaraq bu gün necə kömək edə bilərəm?';
      } else if (name.isNotEmpty) {
        return 'Salam, $name! 👋 Bu gün sənə necə kömək edə bilərəm — iş axtarırsın, yoxsa başqa bir şey?';
      }
    } catch (_) {}

    return 'Salam! 👋 Mən İşçi AI-yam. İş axtarırsansa, elan yerləşdirirsənsə, ya da sadəcə məsləhət lazımdırsa — buradayam!';
  }

  // ─────────────────────────────────────────────────
  //  INPUT HANDLING
  // ─────────────────────────────────────────────────

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

  Future<void> stopListening() async {
    await _voiceService.stopListening();
    emit(state.copyWith(status: AiAssistantStatus.idle));
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _processUserInput(text.trim());
  }

  // ─────────────────────────────────────────────────
  //  CORE PROCESSING
  // ─────────────────────────────────────────────────

  Future<void> _processUserInput(String userText) async {
    // Add user message
    final messagesWithUser = List<AiMessage>.from(state.messages)
      ..add(AiMessage(text: userText, isUser: true));

    emit(state.copyWith(
      messages: messagesWithUser,
      status: AiAssistantStatus.thinking,
      isTyping: true,
      partialText: '',
    ));

    try {
      // Enrich with profile
      final profileSummary = await _profileService.getProfileSummary();
      debugPrint('AiAssistantCubit: Profile: $profileSummary');

      final aiResponse = await _aiService.sendMessage(
        userText,
        userProfileJson: profileSummary,
      );

      debugPrint('AiAssistantCubit: Raw AI response: $aiResponse');

      // Process role detection (done inside AiService._parseRoleFromResponse)
      // Sync role to state
      final detectedRole = _aiService.detectedRole;
      if (detectedRole != state.userRole) {
        emit(state.copyWith(userRole: detectedRole, isTyping: false));
        debugPrint('AiAssistantCubit: Role updated → $detectedRole');
      }

      // Handle special commands
      final aiMessage = await _handleSpecialCommands(aiResponse);

      final finalMessages = List<AiMessage>.from(state.messages)
        ..add(aiMessage);

      emit(state.copyWith(
        messages: finalMessages,
        status: AiAssistantStatus.speaking,
        isTyping: false,
      ));

      // Speak
      await _voiceService.speak(aiMessage.text);
      await _waitForSpeechDone();
      emit(state.copyWith(status: AiAssistantStatus.idle));
    } catch (e, st) {
      debugPrint('AiAssistantCubit error: $e\n$st');
      final errorMessage = AiMessage(
        text: 'Bağışlayın, bir xəta baş verdi. Zəhmət olmasa yenidən cəhd edin.',
        isUser: false,
        type: AiMessageType.error,
      );
      final msgs = List<AiMessage>.from(state.messages)..add(errorMessage);
      emit(state.copyWith(
        messages: msgs,
        status: AiAssistantStatus.idle,
        isTyping: false,
      ));
    }
  }

  // ─────────────────────────────────────────────────
  //  SPECIAL COMMAND HANDLERS
  // ─────────────────────────────────────────────────

  Future<AiMessage> _handleSpecialCommands(String response) async {
    // Strip hidden [ROLE_DETECT] tag from visible text
    String cleanResponse = response
        .replaceAll(
          RegExp(r'\[ROLE_DETECT\].*?\[/ROLE_DETECT\]', dotAll: true),
          '',
        )
        .trim();

    // ── Profile update ──────────────────────────────
    if (cleanResponse.contains('[PROFILE_UPDATE]')) {
      return await _handleProfileUpdate(cleanResponse);
    }

    // ── Job search ──────────────────────────────────
    if (cleanResponse.contains('[JOB_SEARCH]') &&
        cleanResponse.contains('[/JOB_SEARCH]')) {
      return await _handleJobSearch(cleanResponse);
    }

    return AiMessage(text: cleanResponse, isUser: false);
  }

  /// Handle [PROFILE_UPDATE] command
  Future<AiMessage> _handleProfileUpdate(String response) async {
    try {
      final parts = response.split('[PROFILE_UPDATE]');
      final textBefore = parts[0].trim();
      final remainder = parts[1].split('[/PROFILE_UPDATE]');
      final jsonPart = remainder[0]
          .trim()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final textAfter =
          remainder.length > 1 ? remainder[1].trim() : '';

      debugPrint('AiAssistantCubit: Profile JSON: $jsonPart');

      try {
        final profileData = json.decode(jsonPart) as Map<String, dynamic>;
        final success = await _profileService.updateProfileFromAi(profileData);

        if (success) {
          _triggerProfileNotification();
        }
      } catch (e) {
        debugPrint('Profile JSON parse error: $e');
      }

      // Pick most meaningful text part
      String displayText =
          textAfter.isNotEmpty ? textAfter : textBefore;
      if (displayText.isEmpty) {
        displayText = 'Məlumatlarınız profilinizə əlavə edildi! ✅';
      }

      return AiMessage(
        text: displayText,
        isUser: false,
        type: AiMessageType.profileUpdated,
      );
    } catch (e) {
      debugPrint('Profile update handler error: $e');
      final fallback = response
          .replaceAll(
            RegExp(r'\[PROFILE_UPDATE\].*?\[/PROFILE_UPDATE\]', dotAll: true),
            '',
          )
          .trim();
      return AiMessage(
        text: fallback.isNotEmpty ? fallback : 'Profil yeniləndi.',
        isUser: false,
        type: AiMessageType.profileUpdated,
      );
    }
  }

  /// Handle [JOB_SEARCH] command
  Future<AiMessage> _handleJobSearch(String response) async {
    try {
      final jsonStr = response
          .split('[JOB_SEARCH]')[1]
          .split('[/JOB_SEARCH]')[0]
          .trim()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      debugPrint('AiAssistantCubit: Job search JSON: $jsonStr');

      final searchData = json.decode(jsonStr) as Map<String, dynamic>;
      final query = searchData['query'] as String?;
      final limit = searchData['limit'] is int ? searchData['limit'] as int : 5;
      final sortBy = (searchData['sortBy'] as String?) ?? 'relevance';
      final ignoreProfile = searchData['ignoreProfile'] == true;

      // Extract surrounding text
      final messageBefore = response
          .split('[JOB_SEARCH]')[0]
          .replaceAll('```', '')
          .trim();
      final messageAfter = response
          .split('[/JOB_SEARCH]')[1]
          .replaceAll('```', '')
          .trim();

      final introText = messageAfter.isNotEmpty ? messageAfter : messageBefore;

      // Search jobs
      final profile = await _profileService.getUserProfile();
      final jobs = await _jobSearchService.searchJobsForProfile(
        profile,
        query: query,
        limit: limit,
        sortBy: sortBy,
        ignoreProfile: ignoreProfile,
      );

      debugPrint('AiAssistantCubit: Jobs found: ${jobs.length}');

      if (jobs.isEmpty) {
        return AiMessage(
          text: _buildNoJobsMessage(query, sortBy),
          isUser: false,
          type: AiMessageType.jobResults,
        );
      }

      final displayText = introText.isNotEmpty
          ? introText
          : _buildJobFoundMessage(jobs.length, query, sortBy);

      return AiMessage(
        text: displayText,
        isUser: false,
        jobs: jobs,
        type: AiMessageType.jobResults,
      );
    } catch (e) {
      debugPrint('Job search handler error: $e');
      return AiMessage(
        text: 'İş axtarışında xəta baş verdi. Yenidən cəhd edin.',
        isUser: false,
        type: AiMessageType.error,
      );
    }
  }

  /// Build a friendly "no jobs found" message
  String _buildNoJobsMessage(String? query, String sortBy) {
    if (query != null && query.isNotEmpty) {
      return 'Hal-hazırda "$query" üçün aktiv elan tapılmadı. Yeni elanlar çıxanda dərhal görəcəksən! 🔔';
    }
    return 'Hal-hazırda profilinə tam uyğun aktiv elan yoxdur. Profili gücləndirsən, daha çox elan görünəcək!';
  }

  /// Build a friendly "jobs found" message
  String _buildJobFoundMessage(int count, String? query, String sortBy) {
    if (sortBy == 'salary') {
      return 'Ən yüksək maaşlı $count elan — bir bax! 💰';
    }
    if (sortBy == 'date') {
      return 'Ən son $count elan — isti-isti! 🔥';
    }
    if (query != null && query.isNotEmpty) {
      return '"$query" üçün $count uyğun elan tapdım:';
    }
    return 'Sənə $count uyğun elan tapdım:';
  }

  // ─────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────

  void _triggerProfileNotification() {
    if (isClosed) return;
    emit(state.copyWith(showProfileUpdatedNotification: true));
    Future.delayed(const Duration(seconds: 3), () {
      if (!isClosed) {
        emit(state.copyWith(showProfileUpdatedNotification: false));
      }
    });
  }

  Future<void> _waitForSpeechDone() async {
    int maxWait = 60;
    while (_voiceService.isSpeaking && maxWait > 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      maxWait--;
    }
  }
}