import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:azerbaijan_job_marketplace/features/jobs/data/models/job_model.dart';
import 'package:flutter/foundation.dart';

class AiJobSearchService {
  final _firestore = FirebaseFirestore.instance;

  /// İstifadəçinin profilinə uyğun iş elanlarını axtarır
  /// sortBy: 'relevance' (default), 'salary', 'date'
  Future<List<JobModel>> searchJobsForProfile(
    Map<String, dynamic>? profile, {
    String? query,
    int limit = 5,
    String sortBy = 'relevance',
    bool ignoreProfile = false,
  }) async {
    try {
      final snapshot = await _firestore.collection('jobs').get();
      var jobs = snapshot.docs
          .map((d) => JobModel.fromMap(d.data(), d.id))
          .where((j) => j.isActive)
          .toList();

      if (jobs.isEmpty) return [];

      // Create a list of scored jobs
      List<Map<String, dynamic>> scoredJobs = [];

      final userSkills = (profile?['skills'] ?? '').toString().toLowerCase();
      final userCity = (profile?['city'] ?? '').toString().toLowerCase();
      final userExperience = (profile?['experience'] ?? '')
          .toString()
          .toLowerCase();
      final userEducation = (profile?['education'] ?? '')
          .toString()
          .toLowerCase();
      final userBio = (profile?['bio'] ?? '').toString().toLowerCase();

      for (var job in jobs) {
        if (ignoreProfile) {
          // ignoreProfile=true: Bütün işləri daxil et, süzgəcsiz
          int score = _calculateMatchScore(
            job,
            userSkills,
            userCity,
            userExperience,
            userEducation,
            userBio,
            query,
          );
          scoredJobs.add({'job': job, 'score': score > 0 ? score : 1});
        } else {
          int score = _calculateMatchScore(
            job,
            userSkills,
            userCity,
            userExperience,
            userEducation,
            userBio,
            query,
          );

          // Əgər profil və query boşdursa, bütün aktiv işləri göstər
          final allProfileText =
              "\$userSkills \$userExperience \$userEducation \$userBio".trim();
          final hasQuery = query != null && query.isNotEmpty;

          if (allProfileText.isEmpty && !hasQuery) {
            // Profil və query boşdur - bütün işləri göstər
            scoredJobs.add({'job': job, 'score': score > 0 ? score : 1});
          } else if (score > 0) {
            // Profil və ya query var və uyğunluq var
            scoredJobs.add({'job': job, 'score': score});
          }
          // score == 0 və profil/query varsa - bu işi göstərmə
        }
      }

      // If strict filter removed all jobs, return empty
      if (scoredJobs.isEmpty) return [];

      // Sort based on the requested criteria
      if (sortBy == 'salary') {
        // Sort by salary descending (highest first)
        scoredJobs.sort((a, b) {
          final jobA = a['job'] as JobModel;
          final jobB = b['job'] as JobModel;
          return jobB.salaryMin.compareTo(jobA.salaryMin);
        });
      } else if (sortBy == 'date') {
        // Sort by date descending (newest first)
        scoredJobs.sort((a, b) {
          final jobA = a['job'] as JobModel;
          final jobB = b['job'] as JobModel;
          return jobB.createdAt.compareTo(jobA.createdAt);
        });
      } else {
        // Default: sort by relevance score descending
        scoredJobs.sort(
          (a, b) => (b['score'] as int).compareTo(a['score'] as int),
        );
      }

      // Calculate match percentage and add to jobs
      const maxTheoreticalScore = 255;

      final results = scoredJobs.map((e) {
        final job = e['job'] as JobModel;
        final score = e['score'] as int;

        // Calculate match percentage based on theoretical maximum (0-100)
        final matchPercentage = ((score / maxTheoreticalScore) * 100)
            .round()
            .clamp(0, 100);

        return job.copyWith(matchPercentage: matchPercentage);
      }).toList();

      // SADECE %50 ve üzeri eşleşmeleri göster (Kullanıcı isteği)
      final filteredResults = results
          .where((job) => (job.matchPercentage ?? 0) >= 50)
          .toList();

      return filteredResults.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  // Meslek kategorileri ve ilgili anahtar kelimeler
  static const Map<String, List<String>> _professionKeywords = {
    // IT / Proqramlaşdırma
    'it': [
      'proqramlaşdırma',
      'programlama',
      'programming',
      'kod',
      'code',
      'yazılım',
      'software',
      'developer',
      'dev',
      'programmer',
      'coder',
      'flutter',
      'dart',
      'react',
      'vue',
      'angular',
      'node',
      'python',
      'java',
      'javascript',
      'php',
      'laravel',
      'django',
      'spring',
      'dotnet',
      '.net',
      'c#',
      'c++',
      'frontend',
      'backend',
      'fullstack',
      'full-stack',
      'full stack',
      'web developer',
      'mobile developer',
      'app developer',
      'application developer',
      'tətbiq developer',
      'database',
      'verilənlər',
      'api',
      'rest',
      'graphql',
      'software engineer',
      'web development',
      'mobile development',
      'qa',
      'tester',
      'test automation',
      'devops',
      'system admin',
      'network admin',
      'şəbəkə admin',
      'information technology',
      'texnologiya mütəxəssisi',
      'teknoloji mütəxəssisi',
      'kompüter mühəndisi',
      'kompüter ustası',
    ],
    // Aşçı / Mətbəx
    'chef': [
      'aşpaz',
      'aspaz',
      'chef',
      'cook',
      'mutfak',
      'mətbəx',
      'yemek',
      'pişirmə',
      'restoran',
      'kafe',
      'restaurant',
      'cafe',
      'kitchen',
      'culinary',
      'food',
      'şef',
      'sef',
      'aşçı',
      'asci',
      'cooking',
      'cuisine',
      'qida',
      'yemək',
    ],
    // Şoför / Sürücü
    'driver': [
      'şoför',
      'sofor',
      'sürücü',
      'surcu',
      'driver',
      'taksi',
      'taxi',
      'yük',
      'yuk',
      'lojistik',
      'logistics',
      'nəqliyyat',
      'neqliyyat',
      'transport',
      'araç',
      'arac',
      'vehicle',
      'avtomobil',
      'car',
      'truck',
      'kamyon',
    ],
    // Temizlik
    'cleaning': [
      'temizlik',
      'temizlikçi',
      'təmizlik',
      'təmizlikçi',
      'cleaning',
      'cleaner',
      'hijyen',
      'hygiene',
      'sanitasyon',
      'sanitation',
      'təmizləmə',
      'temizleme',
      'housekeeping',
      'janitor',
      'housekeeper',
      'ev təmizliyi',
      'ofis təmizliyi',
      'hadəmə',
      'hademe',
      'xidmətçi',
      'xidmetci',
      'təmizlik işçisi',
      'temizlik iscisi',
      'təmizlik xidməti',
      'temizlik xidmeti',
      'təmizlik işi',
      'temizlik isi',
    ],
    // Satış / Müştəri xidməti
    'sales': [
      'satış',
      'satis',
      'sales',
      'satıcı',
      'satici',
      'seller',
      'mağaza',
      'magaza',
      'market',
      'store',
      'müştəri',
      'musteri',
      'customer',
      'xidmət',
      'xidmet',
      'service',
      'kassir',
      'cashier',
      'retail',
      'pərakəndə',
      'perakende',
    ],
    // Mühasib / Maliyyə
    'accounting': [
      'mühasib',
      'muhasib',
      'accounting',
      'accountant',
      'maliyyə',
      'maliyye',
      'finance',
      'financial',
      'hesabat',
      'report',
      'vergi',
      'tax',
      'audit',
      'büdcə',
      'budce',
      'budget',
      'bank',
      'banka',
      'banking',
    ],
    // Dizayner / Kreativ
    'design': [
      'dizayn',
      'dizayner',
      'design',
      'designer',
      'grafik',
      'graphic',
      'ui',
      'ux',
      'kreativ',
      'creative',
      'photoshop',
      'illustrator',
      'figma',
      'adobe',
      'visual',
      'vizual',
      'art',
      'sənət',
      'sanat',
    ],
    // Menecer / İdarəetmə
    'management': [
      'menecer',
      'manager',
      'idarəetmə',
      'idareetme',
      'management',
      'rəhbər',
      'rehber',
      'leader',
      'koordinator',
      'coordinator',
      'direktor',
      'director',
      'müdir',
      'mudir',
      'başçı',
      'basci',
      'chief',
      'head',
    ],
    // Öğretmen / Təhsil
    'education': [
      'öğretmen',
      'ogretmen',
      'teacher',
      'müəllim',
      'muellim',
      'təhsil',
      'tehsil',
      'education',
      'təlim',
      'telim',
      'training',
      'instructor',
      'təlimatçı',
      'dərs',
      'ders',
      'lesson',
      'məktəb',
      'mekteb',
      'school',
      'universitet',
    ],
    // Doktor / Tibb
    'medical': [
      'doktor',
      'doctor',
      'həkim',
      'hekim',
      'physician',
      'tibb',
      'medical',
      'səhiyyə',
      'sehiyye',
      'health',
      'xəstəxana',
      'xestexana',
      'hospital',
      'klinika',
      'clinic',
      'nurse',
      'tibb bacısı',
      'paramedik',
      'pharmacy',
    ],
    // Marketinq / Reklam
    'marketing': [
      'marketinq',
      'marketing',
      'reklam',
      'advertising',
      'smm',
      'seo',
      'digital',
      'rəqəmsal',
      'reqemsal',
      'sosial',
      'social',
      'media',
      'content',
      'kontent',
      'brand',
      'brend',
      'campaign',
      'kampaniya',
    ],
    // Təmir / Texniki xidmət
    'repair': [
      'təmir',
      'temir',
      'repair',
      'ustası',
      'ustasi',
      'usta',
      'master',
      'tamirci',
      'servis',
      'service',
      'texniki',
      'technical',
      'maintenance',
      'elektrik',
      'electric',
      'santexnik',
      'plumber',
      'mexanik',
      'mechanic',
    ],
    // Təhlükəsizlik / Mühafizə
    'security': [
      'təhlükəsizlik',
      'tehlukesizlik',
      'security',
      'mühafizə',
      'muhafize',
      'guard',
      'qapıçı',
      'qapici',
      'hademe',
      'gatekeeper',
      'protection',
    ],
    // Çatdırılma / Kuryer
    'delivery': [
      'çatdırılma',
      'catdirilma',
      'delivery',
      'kuryer',
      'kurier',
      'courier',
      'göndərmə',
      'gonderme',
      'shipping',
      'logistics',
      'daşıma',
      'dasima',
    ],
  };

  // Eş anlamlı və əlaqəli sözlər (köhnə sistem - yeni sistemə inteqrasiya üçün saxlanır)
  static const Map<String, List<String>> _synonyms = {
    'proqramlaşdırma': [
      'backend',
      'frontend',
      'developer',
      'kod',
      'yazılım',
      'software',
      'programming',
      'web',
      'mobile',
      'app',
      'it',
    ],
    'backend': [
      'node',
      'django',
      'laravel',
      'api',
      'server',
      'database',
      'php',
      'python',
      'java',
    ],
    'frontend': [
      'react',
      'vue',
      'angular',
      'html',
      'css',
      'javascript',
      'ui',
      'ux',
      'web',
    ],
    'dizayn': [
      'design',
      'ui',
      'ux',
      'grafik',
      'graphic',
      'photoshop',
      'figma',
      'adobe',
    ],
    'marketinq': ['marketing', 'reklam', 'smm', 'seo', 'digital', 'sosial'],
    'satış': ['sales', 'müştəri', 'customer', 'biznes', 'business'],
    'mühasib': ['accounting', 'maliyyə', 'finance', 'hesabat', 'vergi'],
    'menecer': ['manager', 'idarəetmə', 'management', 'rəhbər', 'koordinator'],
  };

  /// Kullanıcının mesleğini tespit et (profil metninden)
  String? _detectUserProfession(String profileText) {
    if (profileText.isEmpty) return null;

    final profileLower = profileText.toLowerCase();

    // Meslek skorlarını hesapla - en yüksek skora sahip mesleği seç
    Map<String, int> professionScores = {};

    // Her meslek kategorisi için kontrol et
    for (final entry in _professionKeywords.entries) {
      final profession = entry.key;
      final keywords = entry.value;
      int score = 0;

      // Profil metnini kelimelere ayır
      final profileWords = profileLower.split(RegExp(r'[\s,;.]+'));

      // Eğer profilde bu mesleğe ait anahtar kelimeler varsa
      for (final keyword in keywords) {
        final keywordLower = keyword.toLowerCase();

        // Tam kelime eşleşmesi kontrolü
        for (final word in profileWords) {
          if (word == keywordLower ||
              word.contains(keywordLower) && keywordLower.length > 5) {
            score++;
            break; // Aynı keyword için birden fazla puan verme
          }
        }
      }

      if (score > 0) {
        professionScores[profession] = score;
      }
    }

    // En yüksek skora sahip mesleği döndür
    if (professionScores.isEmpty) return null;

    // Skorları sırala ve en yüksek olanı seç
    final sortedProfessions = professionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topProfession = sortedProfessions.first;
    debugPrint(
      '🎯 MESLEK TESPİTİ: ${topProfession.key} (skor: ${topProfession.value})',
    );

    // Diğer mesleklerin skorlarını da göster
    for (final entry in sortedProfessions) {
      debugPrint('   - ${entry.key}: ${entry.value} puan');
    }

    return topProfession.key;
  }

  /// İşin belirli bir mesleğe uygun olup olmadığını kontrol et
  bool _isJobRelevantForProfession(
    String jobTitle,
    String jobDesc,
    String profession,
  ) {
    final jobTitleLower = jobTitle.toLowerCase();
    final jobDescLower = jobDesc.toLowerCase();

    // Bu mesleğe ait anahtar kelimeleri al
    final keywords = _professionKeywords[profession];
    if (keywords == null) return false;

    // İş başlığını ve açıklamasını kelimelere ayır
    final jobWords = (jobTitleLower + ' ' + jobDescLower).split(
      RegExp(r'[\s,;.]+'),
    );

    // İş başlığı veya açıklamasında bu mesleğe ait kelimeler var mı?
    for (final keyword in keywords) {
      final keywordLower = keyword.toLowerCase();

      // Tam kelime eşleşmesi veya uzun keyword için substring kontrolü
      for (final word in jobWords) {
        if (word == keywordLower ||
            (word.contains(keywordLower) && keywordLower.length > 5)) {
          return true; // Bu iş bu mesleğe uygun
        }
      }
    }

    return false; // Bu iş bu mesleğe uygun değil
  }

  /// İşin kullanıcının mesleğine UYGUN OLMADIĞINI kontrol et (diğer mesleklere ait mi?)
  bool _isJobIrrelevantForProfession(
    String jobTitle,
    String jobDesc,
    String userProfession,
  ) {
    final jobTitleLower = jobTitle.toLowerCase();
    final jobDescLower = jobDesc.toLowerCase();

    // İş başlığını ve açıklamasını kelimelere ayır
    final jobWords = (jobTitleLower + ' ' + jobDescLower).split(
      RegExp(r'[\s,;.]+'),
    );

    // Diğer tüm meslekleri kontrol et
    for (final entry in _professionKeywords.entries) {
      final otherProfession = entry.key;

      // Kullanıcının kendi mesleğini atla
      if (otherProfession == userProfession) continue;

      final keywords = entry.value;

      // Bu iş başka bir mesleğe mi ait?
      int matchCount = 0;
      for (final keyword in keywords) {
        final keywordLower = keyword.toLowerCase();

        // Tam kelime eşleşmesi veya uzun keyword için substring kontrolü
        for (final word in jobWords) {
          if (word == keywordLower ||
              (word.contains(keywordLower) && keywordLower.length > 5)) {
            matchCount++;
            break; // Aynı keyword için birden fazla sayma
          }
        }

        // Eğer 2+ anahtar kelime eşleşirse, bu iş kesinlikle başka mesleğe ait
        if (matchCount >= 2) {
          return true; // Bu iş kullanıcının mesleğine uygun DEĞİL
        }
      }
    }

    return false; // Bu iş başka mesleğe ait değil
  }

  int _calculateMatchScore(
    JobModel job,
    String userSkills,
    String userCity,
    String userExperience,
    String userEducation,
    String userBio,
    String? query,
  ) {
    int cityScore = 0;
    int keywordScore = 0;

    final jobTitle = job.title.toLowerCase();
    final jobDesc = job.description.toLowerCase();

    // ADDIM 1: Kullanıcının mesleğini tespit et
    final allProfileText = "$userSkills $userExperience $userEducation $userBio"
        .trim()
        .toLowerCase();
    final userProfession = _detectUserProfession(allProfileText);

    // DEBUG: Meslek tespitini logla
    if (userProfession != null) {
      debugPrint('🔍 MESLEK TESPİT EDİLDİ: $userProfession');
      debugPrint(
        '📝 Profil metni: ${allProfileText.substring(0, allProfileText.length > 100 ? 100 : allProfileText.length)}...',
      );
      debugPrint('💼 İş: ${job.title}');
    }

    // ADDIM 2: Əgər peşə müəyyən edilibsə, uyğunluğu yoxla
    if (userProfession != null) {
      final isRelevant = _isJobRelevantForProfession(
        jobTitle,
        jobDesc,
        userProfession,
      );
      final isIrrelevant = _isJobIrrelevantForProfession(
        jobTitle,
        jobDesc,
        userProfession,
      );

      debugPrint('   ✅ Uygun mu? $isRelevant');
      debugPrint('   ❌ Alakasız mı? $isIrrelevant');

      // XÜSUSİ QAYDA: IT sahəsi üçün daha yumşaq filtr
      // Çünki IT işləri çox müxtəlif adlandırıla bilər (məs: "1", "2", "it muhendisi")
      if (userProfession == 'it') {
        if (isRelevant) {
          keywordScore += 150; // IT üçün daha yüksək bonus
          debugPrint('   ✨ KABUL EDİLDİ (IT): Mesleğe uygun!');
        } else if (!isIrrelevant) {
          // Əgər digər peşələrə də aid deyilsə (məs: "it muhendisi" kimi ümumi adlar), saxla
          keywordScore += 50;
          debugPrint(
            '   ✨ KABUL EDİLDİ (IT Fallback): Ümumi IT işi ola bilər.',
          );
        } else {
          debugPrint(
            '   🚫 ELENDİ (IT): Başqa peşəyə (məs: aşpaz) tam uyğundur.',
          );
          return 0;
        }
      } else {
        // Digər peşələr üçün mövcud sərt filtr
        if (!isRelevant) {
          debugPrint('   🚫 ELENDİ: Mesleğe uygun değil!');
          return 0;
        }
        if (isIrrelevant) {
          debugPrint('   🚫 ELENDİ: Başqa mesleğe ait!');
          return 0;
        }
        keywordScore += 100;
      }
    }

    // City match - daha esnek
    if (userCity.isNotEmpty) {
      final jobCity = job.city.toLowerCase();
      final userCityLower = userCity.toLowerCase();

      if (jobCity.contains(userCityLower) || userCityLower.contains(jobCity)) {
        cityScore += 30;
      } else if (_fuzzyMatch(jobCity, userCityLower)) {
        cityScore += 15; // Partial city match
      }
    }

    // Profile text match - fuzzy və eş anlamlılarla
    if (allProfileText.isNotEmpty) {
      final profileWords = _extractKeywords(allProfileText);

      for (final word in profileWords) {
        // Direct match
        if (_fuzzyMatch(jobTitle, word)) {
          keywordScore += 40;
        } else if (_fuzzyMatch(jobDesc, word)) {
          keywordScore += 20;
        }

        // Synonym match
        final synonyms = _getSynonyms(word);
        for (final syn in synonyms) {
          if (_fuzzyMatch(jobTitle, syn)) {
            keywordScore += 30; // Slightly lower than direct match
          } else if (_fuzzyMatch(jobDesc, syn)) {
            keywordScore += 15;
          }
        }
      }
    }

    // Query match - ən yüksək prioritet
    bool hasQuery = false;
    if (query != null && query.isNotEmpty) {
      hasQuery = true;
      final queryWords = _extractKeywords(query);

      for (final word in queryWords) {
        // Direct match
        if (_fuzzyMatch(jobTitle, word)) {
          keywordScore += 60; // Query gets highest priority
        } else if (_fuzzyMatch(jobDesc, word)) {
          keywordScore += 30;
        }

        // Synonym match for query
        final synonyms = _getSynonyms(word);
        for (final syn in synonyms) {
          if (_fuzzyMatch(jobTitle, syn)) {
            keywordScore += 45;
          } else if (_fuzzyMatch(jobDesc, syn)) {
            keywordScore += 20;
          }
        }
      }
    }

    // DAHA ESNEK QAYDA: Minimum xal eşiyi
    // Əgər profil və ya query varsa, amma heç bir uyğunluq yoxdursa
    // Yalnız çox aşağı xal ver (şəhər uyğunluğu varsa saxla)
    if ((allProfileText.isNotEmpty || hasQuery) && keywordScore == 0) {
      // Əgər şəhər uyğundursa, kiçik xal ver (tamamilə ləğv etmə)
      if (cityScore > 0) {
        return cityScore; // Yalnız şəhər xalı
      }
      return 0; // Heç bir uyğunluq yoxdur
    }

    int bonusScore = 0;
    // Date bonus — newer jobs ranked higher
    final daysSinceCreated = DateTime.now().difference(job.createdAt).inDays;
    if (daysSinceCreated < 3) {
      bonusScore += 15;
    } else if (daysSinceCreated < 7) {
      bonusScore += 10;
    } else if (daysSinceCreated < 14) {
      bonusScore += 5;
    }

    // Urgent jobs get a boost
    if (job.isUrgent) {
      bonusScore += 10;
    }

    // Yekun xal
    return keywordScore + cityScore + bonusScore;
  }

  /// Fuzzy matching - substring və case-insensitive
  bool _fuzzyMatch(String text, String keyword) {
    if (keyword.length < 3) return false;

    final textLower = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final keywordLower = keyword.toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    // Exact substring match
    if (textLower.contains(keywordLower)) return true;

    // Partial match - at least 70% of keyword appears in text
    if (keywordLower.length >= 5) {
      final minMatch = (keywordLower.length * 0.7).round();
      int matchCount = 0;

      for (int i = 0; i <= keywordLower.length - minMatch; i++) {
        final substr = keywordLower.substring(i, i + minMatch);
        if (textLower.contains(substr)) {
          matchCount++;
          if (matchCount >= 1) return true;
        }
      }
    }

    return false;
  }

  /// Açar sözləri çıxar və təmizlə
  List<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .replaceAll(',', ' ')
        .replaceAll(';', ' ')
        .replaceAll('.', ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Eş anlamlı sözləri tap
  List<String> _getSynonyms(String word) {
    final wordLower = word.toLowerCase();

    // Direct lookup
    if (_synonyms.containsKey(wordLower)) {
      return _synonyms[wordLower]!;
    }

    // Reverse lookup - if word is a synonym of something
    for (final entry in _synonyms.entries) {
      if (entry.value.contains(wordLower)) {
        return [entry.key, ...entry.value];
      }
    }

    return [];
  }

  /// İş elanlarını AI-yə müxtəsər forma halında qaytarır
  String formatJobsForAi(List<JobModel> jobs) {
    if (jobs.isEmpty) return 'Heç bir uyğun elan tapılmadı.';

    final buffer = StringBuffer();
    for (int i = 0; i < jobs.length; i++) {
      final j = jobs[i];
      buffer.writeln('${i + 1}. ${j.title} — ${j.companyName}');
      buffer.writeln('   Maaş: ${j.salaryText}');
      buffer.writeln('   Şəhər: ${j.city}, ${j.district}');
      buffer.writeln('   Növ: ${j.jobType}');
      if (j.experienceLevel != null)
        buffer.writeln('   Təcrübə: ${j.experienceLevel}');
      if (j.educationLevel != null)
        buffer.writeln('   Təhsil: ${j.educationLevel}');
      buffer.writeln();
    }
    return buffer.toString();
  }
}
