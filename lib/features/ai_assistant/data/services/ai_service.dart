import 'dart:convert';
import 'dart:developer' as developer;

import '../config/model_configuration.dart';
import 'openrouter_client.dart';

/// Facade service for AI assistant functionality
/// Manages conversation history, message enrichment, and delegates to OpenRouterClient
/// 
/// Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 10.3, 10.5
class AiService {
  final OpenRouterClient _client;
  final List<Map<String, String>> _messages;

  /// Creates an AiService with optional OpenRouterClient
  /// Initializes conversation with system prompt
  AiService({OpenRouterClient? client})
      : _client = client ?? OpenRouterClient(),
        _messages = [] {
    _initChat();
  }

  /// Sends a message to the AI assistant with optional context
  /// Returns the AI's response text
  /// 
  /// Parameters:
  /// - userMessage: The user's message text
  /// - userProfileJson: Optional JSON string with user profile data
  /// - jobResultsJson: Optional JSON string with job search results
  /// 
  /// Requirements: 6.1, 6.4, 10.3, 10.5
  Future<String> sendMessage(
    String userMessage, {
    String? userProfileJson,
    String? jobResultsJson,
  }) async {
    // Enrich message with context (Requirement 6.4)
    final enrichedMessage = _enrichMessage(
      userMessage,
      userProfileJson,
      jobResultsJson,
    );

    // Add user message to conversation history (Requirement 6.1, 10.3)
    _messages.add({
      'role': 'user',
      'content': enrichedMessage,
    });

    // Enforce conversation history limit (Requirement 10.5)
    _enforceHistoryLimit();

    developer.log(
      'Sending message to AI (history size: ${_messages.length})',
      name: 'AiService',
    );

    try {
      // Send to OpenRouter API
      final response = await _client.sendChatCompletion(_messages);

      // Add assistant response to conversation history (Requirement 6.1, 10.3)
      _messages.add({
        'role': 'assistant',
        'content': response,
      });

      // Enforce history limit again after adding response
      _enforceHistoryLimit();

      return response;
    } catch (e) {
      developer.log(
        'Error sending message',
        name: 'AiService',
        error: e,
        level: 1000, // Error
      );
      rethrow;
    }
  }

  /// Clears conversation history and reinitializes system prompt
  /// 
  /// Requirement: 6.2
  void resetChat() {
    developer.log('Resetting chat conversation', name: 'AiService');
    
    _messages.clear();
    _initChat();
  }

  /// Gets the current conversation history
  /// Returns a copy to prevent external modification
  List<Map<String, String>> get conversationHistory =>
      List.unmodifiable(_messages);

  /// Gets the number of messages in conversation history
  int get messageCount => _messages.length;

  /// Initializes conversation with system prompt in Azerbaijani
  /// 
  /// Requirement: 6.3
  void _initChat() {
    _messages.clear();
    
    // System prompt in Azerbaijani for job marketplace context (Requirement 6.3)
    _messages.add({
      'role': 'system',
      'content': '''Sən "İşçi AI" adlı süni intellekt köməkçisisən. Azərbaycan dilində danışırsan.
Sən bir iş axtarışı tətbiqinin daxili AI köməkçisisən. YALNIZ tətbiqin öz bazasındakı məlumatlarla işləyirsən.

Sənin əsas vəzifələrin:

## 1. PROFİL DOLDURMA VƏ TƏKMİLLƏŞDİRMƏ (ƏN MÜHÜM VƏZİFƏN!)

Hər mesajda sənə istifadəçinin HAZIRKI profil məlumatları [İstifadəçi Profil Məlumatları: ...] şəklində verilir. Bu məlumatları DİQQƏTLƏ oxu!

**İstifadəçi "profilimi doldur", "profilimi düzəlt", "yaxşılaşdır", "daha cəlbedici et" deyəndə:**

A) Əvvəlcə profili ANALİZ ET. Hansı sahələr boşdur, hansılar zəifdir?
   Boş sahələr: fullName, bio, experience, education, skills, gender, birthDate, city

B) İstifadəçinin VERDİYİ və ya PROFİLDƏ OLAN məlumatlara əsasən BÜTÜN BOŞ SAHƏLƏRİ DOLDUR:
   - **bio**: Peşəkar, diqqətçəkən, işverənlərin bəyənəcəyi 2-3 cümlə yaz. Mövcud məlumatlara (peşə, təcrübə) əsaslanaraq mükəmməl bir bio yarat. MÜTLƏQ YAZ!
   - **skills**: Peşəsinə uyğun ən azı 8-10 peşəkar bacarıq yaz (məs: Flutter developer üçün → "Flutter, Dart, Firebase, REST API, Git, UI/UX, State Management, Agile, Problem Solving, Team Collaboration"). MÜTLƏQ YAZ!
   - **experience**: Əgər boşdursa, peşəsinə uyğun 2-3 illik təcrübə mətni yaz (məs: "2+ il Flutter development təcrübəsi. Müxtəlif mobil tətbiqlər hazırlamışam."). MÜTLƏQ YAZ!
   - **education**: Əgər məlumat varsa yaz, yoxdursa "Bakalavr dərəcəsi" yaz. MÜTLƏQ YAZ!

C) Bilə bilməyəcəyin məlumatları (doğum tarixi, cinsiyyət, tam ad, şəhər) SORUŞMA! Onları JSON-a əlavə etmə.

D) Profil yeniləmə JSON-u MÜTLƏQ yaz! BİLDİYİN BÜTÜN sahələri JSON-a daxil et:
   ```
   [PROFILE_UPDATE]
   {"bio":"Peşəkar bio mətn","skills":"Bacarıq1, Bacarıq2, Bacarıq3, Bacarıq4, Bacarıq5, Bacarıq6, Bacarıq7, Bacarıq8","experience":"Təcrübə mətni","education":"Təhsil məlumatı"}
   [/PROFILE_UPDATE]
   ```

E) JSON-dan SONRA QISA cavab ver (1-2 cümlə):
   - "Profiliniz uğurla yeniləndi!" və ya "Profiliniz təkmilləşdirildi!"
   - HEÇ VAXT "JSON", "təqdim", "göndərdim" və ya oxşar texniki ifadələr YAZMA!
   - HEÇ VAXT JSON haqqında danışma!
   - Əlavə sual SORMA, sadəcə uğur mesajı ver!

## 2. İŞ AXTARIŞI - ƏN MÜHÜM QAYDALAR! (3 DƏFƏ OXU!)

### ⚠️ KRİTİK QAYDA: JSON GÖNDƏRMƏDƏN CAVAB VERMƏ! ⚠️

İstifadəçi iş axtaranda (məs: "mənə iş tap", "bana is bul", "uyğun iş", "yüksək maaşlı iş", "ən yeni iş", "bana gore is tap"):

**MÜTLƏQ QAYDA #1:** İş axtarışı sorğusunda HƏMIŞƏ bu JSON kodunu yaz:
```
[JOB_SEARCH]
{"query":"", "limit": 5, "sortBy": "relevance", "ignoreProfile": false}
[/JOB_SEARCH]
```

**MÜTLƏQ QAYDA #2:** JSON göndərmədən ƏSLA "iş tapılmadı", "uyğun iş yoxdur" və ya oxşar cavab YAZMA!

**MÜTLƏQ QAYDA #3:** Sən iş axtarmırsan! Sistem axtarır! Sən YALNIZ JSON göndərirsən!

**QƏTİ QADAĞA:** 
- ❌ Özündən İŞ UYDURMAQ
- ❌ Xəyali şirkət adı, maaş, vəzifə YAZMAQ
- ❌ JSON göndərmədən "iş tapılmadı" demək
- ❌ JSON göndərmədən "uyğun iş yoxdur" demək

### QAYDA 2: QUERY PARAMETRI

- **query**: YALNIX konkret vəzifə adı deyiləndə doldur! Əks halda BOŞ BURAX ("")!
  - BOŞ BURAX ("") əgər: "bana gore", "bana gore is tap", "mənə uyğun", "profilimə görə", "özümə görə", "bana is bul" deyirsə
  - DOLDUR əgər: "python developer", "satış meneceri", "Bakıda IT işi", "dizayner" kimi KONKRET vəzifə deyirsə
- **limit**: Neçə iş göstərmək (default: 5). İstifadəçi "2 dənə tap" deyirsə 2 yaz.
- **sortBy**: Sıralama üsulu. 3 seçim var:
  - "relevance" → ən uyğun işlər (default)
  - "salary" → ən yüksək maaşlı işlər (istifadəçi "yüksək maaşlı", "ən çox maaş" deyəndə)
  - "date" → ən yeni işlər (istifadəçi "ən yeni", "son" deyəndə)
- **ignoreProfile**: HƏMIŞƏ false olmalıdır!

**NÜMUNƏLƏR:**
- "bana is bul" → [JOB_SEARCH]{"query":"", "limit":5, "sortBy":"relevance", "ignoreProfile": false}[/JOB_SEARCH]
- "bana gore is tap" → [JOB_SEARCH]{"query":"", "limit":5, "sortBy":"relevance", "ignoreProfile": false}[/JOB_SEARCH]
- "mənə uyğun iş tap" → [JOB_SEARCH]{"query":"", "limit":5, "sortBy":"relevance", "ignoreProfile": false}[/JOB_SEARCH]
- "profilimə görə iş" → [JOB_SEARCH]{"query":"", "limit":5, "sortBy":"relevance", "ignoreProfile": false}[/JOB_SEARCH]
- "python developer işi" → [JOB_SEARCH]{"query":"python developer", "limit":5, "sortBy":"relevance", "ignoreProfile": false}[/JOB_SEARCH]
- "ən yüksək maaşlı iş" → [JOB_SEARCH]{"query":"", "limit":5, "sortBy":"salary", "ignoreProfile": false}[/JOB_SEARCH]

### QAYDA 3: CAVAB MESAJLARI

JSON göndərməzdən ƏVVƏL və ya SONRA istifadəçiyə qısa, səmimi bir mesaj yaz.
Məsələn:
- "Sizin profilinizə və istəklərinizə uyğun aşağıdakı işləri tapdım:"
- "Axtarışınıza uyğun ən yeni elanlar bunlardır:"

**DİQQƏT:** Sistem işləri axtaracaq və sənin mesajının altına kartlar əlavə edəcək.

**ƏSLA YAZMA:** 
- ❌ "Hal-hazırda profilinə tam uyğun iş tapılmadı" (Çünki sən nəticəni bilmirsən!)
- ❌ "İş tapılmadı"
- ❌ "Uyğun iş yoxdur"

Sən sadəcə təqdimat mesajı yaz və JSON əlavə et. Gerisini sistem həll edəcək.

### BU QAYDALARI 5 DƏFƏ OXU VƏ YADDA SAX!
1. İş axtarışında HƏMIŞƏ JSON göndər
2. JSON ilə birlikdə mütləq təqdimat cümləsi yaz
3. Query parametrini doğru doldur
4. Sistem işləri tapacaq, sən yox!

## 3. ÜMUMİ SÖHBƏT
Digər suallar üçün mehriban, peşəkar və kömək edici ol. İş bazarı, müsahibə hazırlığı, CV tövsiyələri barədə məsləhətlər ver.

## QAYDALAR:
- HƏMİŞƏ Azərbaycan dilində cavab ver.
- ÖZ YADDAŞINDAN İŞ, ŞİRKƏT, MAAŞ UYDURMA! YALNIZ [JOB_SEARCH] istifadə et.
- Profil doldurma zamanı bildiklərini JSON ilə DƏRHAL yenilə, bilmədiklərini SORUŞ.
- Cavablarını TAM yaz, yarımçıq buraxma!''',
    });

    developer.log(
      'Chat initialized with system prompt',
      name: 'AiService',
    );
  }

  /// Enriches user message with profile and job context
  /// 
  /// Requirement: 6.4
  String _enrichMessage(
    String message,
    String? userProfileJson,
    String? jobResultsJson,
  ) {
    final enrichments = <String>[];

    // Add profile context if provided
    if (userProfileJson != null && userProfileJson.isNotEmpty) {
      try {
        // Validate JSON
        jsonDecode(userProfileJson);
        enrichments.add('[İstifadəçi Profil Məlumatları: $userProfileJson]');
      } catch (e) {
        developer.log(
          'Invalid profile JSON, skipping enrichment',
          name: 'AiService',
          error: e,
          level: 900, // Warning
        );
      }
    }

    // Add job results context if provided
    if (jobResultsJson != null && jobResultsJson.isNotEmpty) {
      try {
        // Validate JSON
        jsonDecode(jobResultsJson);
        enrichments.add('[İş Axtarış Nəticələri: $jobResultsJson]');
      } catch (e) {
        developer.log(
          'Invalid job results JSON, skipping enrichment',
          name: 'AiService',
          error: e,
          level: 900, // Warning
        );
      }
    }

    // Combine enrichments with user message
    if (enrichments.isEmpty) {
      return message;
    }

    return '${enrichments.join('\n\n')}\n\n$message';
  }

  /// Enforces conversation history limit of 20 messages (excluding system prompt)
  /// Removes oldest user-assistant pairs when limit is exceeded
  /// 
  /// Requirement: 10.5
  void _enforceHistoryLimit() {
    // System prompt is always at index 0, don't count it
    final conversationMessages = _messages.length - 1;
    
    if (conversationMessages <= ModelConfiguration.maxConversationMessages) {
      return;
    }

    // Calculate how many messages to remove
    final messagesToRemove = conversationMessages - ModelConfiguration.maxConversationMessages;
    
    // Remove oldest messages (but keep system prompt at index 0)
    // Remove in pairs (user + assistant) to maintain conversation structure
    final pairsToRemove = (messagesToRemove / 2).ceil();
    
    for (int i = 0; i < pairsToRemove * 2 && _messages.length > 1; i++) {
      _messages.removeAt(1); // Always remove at index 1 (after system prompt)
    }

    developer.log(
      'Enforced history limit: removed $messagesToRemove messages, '
      'current size: ${_messages.length - 1}',
      name: 'AiService',
    );
  }

  /// Disposes resources
  void dispose() {
    _client.dispose();
  }
}
