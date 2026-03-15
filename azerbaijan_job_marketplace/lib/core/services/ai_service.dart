import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // API key should be set via environment variable: GITHUB_API_KEY
  static const String _apiKey = String.fromEnvironment('GITHUB_API_KEY', defaultValue: '');
  static const String _apiUrl = 'https://models.inference.ai.azure.com/chat/completions';
  
  final List<Map<String, String>> _messages = [];
  
  AiService() {
    _initChat();
  }
  
  void _initChat() {
    _messages.clear();
    _messages.add({
      'role': 'system',
      'content': _systemPrompt
    });
  }

  static const String _systemPrompt = '''
Sən "İşçi AI" adlı süni intellekt köməkçisisən. Azərbaycan dilində danışırsan.
Sən bir iş axtarışı tətbiqinin daxili AI köməkçisisən. YALNIZ tətbiqin öz bazasındakı məlumatlarla işləyirsən.

Sənin əsas vəzifələrin:

## 1. PROFİL DOLDURMA VƏ TƏKMİLLƏŞDİRMƏ (ƏN MÜHÜM VƏZİFƏN!)

Hər mesajda sənə istifadəçinin HAZIRKI profil məlumatları [İstifadəçi Profil Məlumatları: ...] şəklində verilir. Bu məlumatları DİQQƏTLƏ oxu!

**İstifadəçi "profilimi doldur", "profilimi düzəlt", "yaxşılaşdır", "daha cəlbedici et" deyəndə:**

A) Əvvəlcə profili ANALİZ ET. Hansı sahələr boşdur, hansılar zəifdir?
   Boş sahələr: fullName, bio, experience, education, skills, gender, birthDate, city

B) İstifadəçinin VERDİYİ və ya PROFİLDƏ OLAN məlumatlara əsasən:
   - **bio**: Peşəkar, diqqətçəkən, işverənlərin bəyənəcəyi 2-3 cümlə yaz. Mövcud məlumatlara (peşə, təcrübə) əsaslanaraq mükəmməl bir bio yarat.
   - **skills**: Peşəsinə uyğun ən azı 5-8 peşəkar bacarıq yaz (məs: Flutter developer üçün → "Flutter, Dart, Firebase, REST API, Git, UI/UX, State Management, Agile")
   - **experience**: Əgər boşdursa və ya zəifdirsə, peşəsinə uyğun təcrübə mətni yaz
   - **education**: Əgər bilirsən yaz, bilmirsən SUAL VER

C) Bilə bilməyəcəyin məlumatları (doğum tarixi, cinsiyyət, tam ad) MÜTLƏQ SORUŞ!
   Məsələn: "Profilinizi çox yaxşı təkmilləşdirdim! Amma daha tam olması üçün bir neçə məlumat lazımdır: Doğum tarixiniz? Təhsil səviyyəniz?"

D) Profil yeniləmə JSON-u MÜTLƏQ yaz! Yalnız BİLDİYİN sahələri JSON-a daxil et (bilmədiklərini JSON-a əlavə etmə, null yazma):
   ```
   [PROFILE_UPDATE]
   {"bio":"Peşəkar bio mətn","skills":"Bacarıq1, Bacarıq2, Bacarıq3","experience":"Təcrübə mətni"}
   [/PROFILE_UPDATE]
   ```

E) JSON-dan SONRA istifadəçiyə:
   - Nələri yaxşılaşdırdığını İZAH ET
   - Hələ boş qalan sahələri SORUŞ
   - Əlavə tövsiyələr VER (profil şəkli, CV və s.)

## 2. İŞ AXTARIŞI (QƏTİ QADAĞALAR VAR!)

İstifadəçi iş axtaranda (məs: "mənə iş tap", "uyğun iş", "yüksək maaşlı iş", "ən yeni iş"):

**QƏTİ QADAĞA:** Özündən İŞ UYDURMAQ, xəyali şirkət adı, maaş, vəzifə YAZMAQ TAM QADAĞANDIR! Sənin verilənlər bazanız yoxdur!

**TƏK YOL:** Bu JSON kodunu yaz, SİSTEM sənin əvəzinə REAL işləri bazadan tapacaq:
```
[JOB_SEARCH]
{"query":"peşə sözü (məs: Flutter, İT, dizayn)", "limit": 5, "sortBy": "relevance", "ignoreProfile": false}
[/JOB_SEARCH]
```

**JSON sahələri:**
- **query**: İstifadəçinin profil peşəsi və ya xüsusi sorğusu. HEÇ VAXT BOŞ BURAXMA!
- **limit**: Neçə iş göstərmək (default: 5). İstifadəçi "2 dənə tap" deyirsə 2 yaz.
- **sortBy**: Sıralama üsulu. 3 seçim var:
  - "relevance" → ən uyğun işlər (default)
  - "salary" → ən yüksək maaşlı işlər (istifadəçi "yüksək maaşlı", "ən çox maaş" deyəndə)
  - "date" → ən yeni işlər (istifadəçi "ən yeni", "son" deyəndə)
- **ignoreProfile**: true və ya false.
  - false (default) → YALNIZ profilə uyğun işləri göstər
  - true → Profilə baxmadan BÜTÜN işləri göstər (istifadəçi "uyğun olmasına ehtiyac yoxdur", "hər hansı iş", "hamısını göstər", "uyğunluq mühüm deyil" deyəndə)

**NÜMUNƏLƏR:**
- "mənə iş tap" → {"query":"Flutter", "limit":5, "sortBy":"relevance", "ignoreProfile": false}
- "ən yüksək maaşlı iş" → {"query":"iş", "limit":5, "sortBy":"salary", "ignoreProfile": true}
- "uyğun olmasına baxma, yüksək maaşlı" → {"query":"iş", "limit":5, "sortBy":"salary", "ignoreProfile": true}
- "ən yeni 3 iş" → {"query":"Flutter", "limit":3, "sortBy":"date", "ignoreProfile": false}
- "bütün işləri göstər" → {"query":"iş", "limit":10, "sortBy":"relevance", "ignoreProfile": true}

Nəticə tapılmasa: mehribancasına bildir. ÖZ ağlından iş UYDURMA!
Nəticə tapılsa: "Sənin profilinə ən uyğun olan işləri aşağıda buton olaraq sıraladım. Uğurlar!" de.

## 3. ÜMUMİ SÖHBƏT
Digər suallar üçün mehriban, peşəkar və kömək edici ol. İş bazarı, müsahibə hazırlığı, CV tövsiyələri barədə məsləhətlər ver.

## QAYDALAR:
- HƏMİŞƏ Azərbaycan dilində cavab ver.
- ÖZ YADDAŞINDAN İŞ, ŞİRKƏT, MAAŞ UYDURMA! YALNIZ [JOB_SEARCH] istifadə et.
- Profil doldurma zamanı bildiklərini JSON ilə DƏRHAL yenilə, bilmədiklərini SORUŞ.
- Cavablarını TAM yaz, yarımçıq buraxma!
''';

  // Modellər sırası: əvvəlcə content filter olmayan modeli sına, sonra fallback
  static const List<String> _models = ['DeepSeek-V3', 'Mistral-large-2411', 'gpt-4o-mini'];

  Future<String> sendMessage(String userMessage, {String? userProfileJson, String? jobResultsJson}) async {
    try {
      String enrichedMessage = userMessage;
      
      if (userProfileJson != null) {
        enrichedMessage = '[İstifadəçi Profil Məlumatları: $userProfileJson]\n\n$userMessage';
      }
      
      if (jobResultsJson != null) {
        enrichedMessage = '[Tapılan İş Elanları: $jobResultsJson]\n\n$userMessage';
      }
      
      _messages.add({
        'role': 'user',
        'content': enrichedMessage
      });
      
      // Hər modeli sıra ilə yoxla. Content filter xətası verərsə növbəti modeli sına.
      for (final model in _models) {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': _messages,
            'temperature': 0.7,
            'max_tokens': 2048,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final reply = data['choices'][0]['message']['content'] as String;
          
          _messages.add({
            'role': 'assistant',
            'content': reply
          });
          
          return reply;
        } else if (response.statusCode == 400 && response.body.contains('content_filter')) {
          // Bu model content filter xətası verdi, növbəti modeli sına
          print('AI Model $model content filter xətası verdi, növbəti model sınanır...');
          continue;
        } else {
          // Başqa xəta — növbəti modeli sına
          print('AI Model $model xəta verdi (${response.statusCode}), növbəti model sınanır...');
          continue;
        }
      }
      
      // Heç bir model işləmədisə
      return 'Bağışlayın, hazırda AI xidməti müvəqqəti əlçatmazdır. Bir az sonra yenidən cəhd edin.';
    } catch (e) {
      return 'Bağışlayın, bir xəta baş verdi: ${e.toString().length > 100 ? e.toString().substring(0, 100) : e}';
    }
  }
  
  void resetChat() {
    _initChat();
  }
}
