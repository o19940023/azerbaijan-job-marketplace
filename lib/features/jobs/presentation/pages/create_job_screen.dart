import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/job_categories.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../data/models/job_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../map/presentation/pages/map_picker_screen.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:azerbaijan_job_marketplace/features/jobs/presentation/pages/payment_webview_screen.dart';

class CreateJobScreen extends StatefulWidget {
  final JobModel? existingJob;

  const CreateJobScreen({super.key, this.existingJob});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _addressController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _requirementController = TextEditingController();

  String _selectedCategory = 'waiter';
  String _selectedJobType = 'fullTime';
  String _selectedSalaryPeriod = 'aylıq';
  String _selectedCity = 'Bakı';
  LatLng? _selectedLocation;
  final List<String> _requirements = [];
  final List<String> _selectedBenefits = [];
  final _availableBenefits = [
    'Yemək',
    'Yol',
    'Sığorta',
    'Bonus/Prim',
    'Nəqliyyat',
    'Sərbəst qrafik',
  ];
  bool _isUrgent = false;
  bool _isSubmitting = false;
  String? _companyLogoUrl;
  bool _isUploadingLogo = false;
  String _selectedEducation = 'Vacib deyil';
  String _selectedExperience = 'Təcrübəsiz';
  bool _allowCallIfAccepted = true;
  String _applicationMethod = 'in_app';
  final _externalUrlController = TextEditingController();
  int? _urgentDays;

  @override
  void initState() {
    super.initState();
    if (widget.existingJob != null) {
      final job = widget.existingJob!;
      _titleController.text = job.title;
      _descriptionController.text = job.description;
      _salaryMinController.text = job.salaryMin.toString();
      if (job.salaryMax != null) {
        _salaryMaxController.text = job.salaryMax.toString();
      }
      _workingHoursController.text = job.workingHours ?? '';
      _selectedCategory = job.categoryId;
      _selectedJobType = job.jobType;
      _selectedSalaryPeriod = job.salaryPeriod;
      _selectedCity = job.city;
      _selectedLocation = LatLng(job.latitude, job.longitude);
      _requirements.addAll(job.requirements);
      _selectedBenefits.addAll(job.benefits);
      _isUrgent = job.isUrgent;
      // Eğer acil ilansa, default olarak 1 gün seç (gerçek değer önemli değil, sadece validation geçmek için)
      if (job.isUrgent) {
        _urgentDays = 1;
      }
      _companyLogoUrl = job.companyLogo;
      _selectedEducation = job.educationLevel ?? 'Vacib deyil';
      _selectedExperience = job.experienceLevel ?? 'Təcrübəsiz';
      _allowCallIfAccepted = job.allowCallIfAccepted;
      _applicationMethod = job.applicationMethod;
      _externalUrlController.text = job.externalUrl ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _workingHoursController.dispose();
    _requirementController.dispose();
    _externalUrlController.dispose();
    super.dispose();
  }

  void _submitJob() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zəhmət olmasa xəritədən iş yerinin mövqeyini seçin.'),
        ),
      );
      return;
    }

    // Acil ilan seçilmişse ama gün sayısı seçilmemişse
    if (_isUrgent && (_urgentDays == null || ![1, 5, 10].contains(_urgentDays))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Təcili elan üçün gün sayını seçin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      String companyName = 'Şirkət';
      String phone = '';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          companyName = data['fullName'] ?? 'Şirkət';
          phone = data['phone'] ?? '';
        }
      } catch (e) {
        // Ignored for fallback
      }

      if (!mounted) return;

      final jobId =
          widget.existingJob?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // EĞER EDIT YAPILIYORSA VE ZATEN ACİL İLANSA, TEKRAR ÖDEME İSTEME!
      final bool isEditingUrgentJob = widget.existingJob != null && widget.existingJob!.isUrgent;
      
      // EĞER ACİL İLAN SEÇİLMİŞSE VE YENİ İLANSA, ÖDEME YAPILACAK
      if (_isUrgent && _urgentDays != null && !isEditingUrgentJob) {
        await _handleUrgentPayment(jobId, currentUser.uid, companyName, phone);
      } else {
        // Normal ilan VEYA zaten acil olan ilan düzenleniyor - direkt kaydet
        await _saveJobToFirestore(jobId, currentUser.uid, companyName, phone, _isUrgent);
        
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        
        _showSuccessDialog(isUrgent: _isUrgent);
      }
    });
  }

  Future<void> _saveJobToFirestore(
    String jobId,
    String employerId,
    String companyName,
    String phone,
    bool isUrgent,
  ) async {
    final newJob = JobModel(
      id: jobId,
      title: _titleController.text,
      companyName: companyName,
      city: _selectedCity,
      district: '',
      salaryMin: double.tryParse(_salaryMinController.text) ?? 0,
      salaryMax: double.tryParse(_salaryMaxController.text),
      salaryPeriod: _selectedSalaryPeriod,
      jobType: _selectedJobType,
      workingHours: _workingHoursController.text.isNotEmpty
          ? _workingHoursController.text
          : null,
      address: null,
      description: _descriptionController.text,
      requirements: List.from(_requirements),
      benefits: List.from(_selectedBenefits),
      categoryId: _selectedCategory,
      employerId: employerId,
      isActive: true,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      contactPhone: phone,
      createdAt: widget.existingJob?.createdAt ?? DateTime.now(),
      expiresAt:
          widget.existingJob?.expiresAt ??
          DateTime.now().add(const Duration(days: 45)),
      companyLogo: _companyLogoUrl,
      educationLevel: _selectedEducation,
      experienceLevel: _selectedExperience,
      viewCount: widget.existingJob?.viewCount ?? 0,
      applicationCount: widget.existingJob?.applicationCount ?? 0,
      allowCallIfAccepted: _allowCallIfAccepted,
      applicationMethod: _applicationMethod,
      externalUrl: _applicationMethod == 'redirect'
          ? _externalUrlController.text.trim()
          : null,
      isUrgent: isUrgent,
      // EĞER MEVCUT İŞ ACİLSE, urgentUntil VE urgentTransaction ALANLARINI KORU!
      urgentUntil: widget.existingJob?.urgentUntil,
      urgentTransaction: widget.existingJob?.urgentTransaction,
    );

    final jobMap = newJob.toMap();
    debugPrint('Saving job with isUrgent: ${jobMap['isUrgent']}');

    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .set(jobMap);
  }

  Future<void> _handleUrgentPayment(
    String jobId,
    String employerId,
    String companyName,
    String phone,
  ) async {
    final days = _urgentDays!;
    final Uri url = Uri.parse(
      'https://istap-backend-1.onrender.com/api/createUrgentPayment',
    );
    final body = {
      'jobId': jobId,
      'employerId': employerId,
      'days': days.toString(),
    };

    try {
      // İlk önce ilanı NORMAL olarak kaydet
      await _saveJobToFirestore(jobId, employerId, companyName, phone, false);
      
      if (!mounted) return;

      // Ödeme isteği gönder
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('Payment request status: ${resp.statusCode}');
      debugPrint('Payment request body: ${resp.body}');

      if (resp.statusCode != 200) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ödəniş xətası: Status ${resp.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final redirectUrl = (data['redirect_url'] ?? '').toString();
      final orderId = 'urgent_${jobId}_${DateTime.now().millisecondsSinceEpoch}';
      final transaction = (data['transaction'] ?? '').toString();

      if (redirectUrl.isEmpty) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ödəniş linki alınmadı: ${data['error'] ?? "Xəta"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // WebView'i aç
      final paymentResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(url: redirectUrl),
        ),
      );

      if (!mounted) return;

      if (paymentResult == true) {
        // Ödeme başarılı - Firestore güncellemesini kontrol et
        await _verifyAndUpdateUrgentStatus(jobId, orderId, transaction, days);
      } else {
        // Ödeme iptal veya başarısız
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödəniş ləğv edildi və ya uğursuz oldu.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Payment error: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödəniş xətası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyAndUpdateUrgentStatus(
    String jobId,
    String orderId,
    String transaction,
    int days,
  ) async {
    if (!mounted) return;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Ödəniş təsdiqlənir...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    // Retry mekanizması ile checkPaymentStatus çağır
    bool isUpdated = false;
    bool paymentActuallySucceeded = false;
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries && !isUpdated) {
      retryCount++;
      debugPrint('Checking payment status, attempt $retryCount/$maxRetries');

      try {
        // Önce Firestore'u kontrol et - belki webhook zaten güncelledi
        final jobDoc = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(jobId)
            .get();

        if (jobDoc.exists && jobDoc.data()?['isUrgent'] == true) {
          debugPrint('Job already marked as urgent by webhook');
          isUpdated = true;
          paymentActuallySucceeded = true;
          break;
        }

        // Firestore güncel değilse, backend'den status kontrol et
        await Future.delayed(Duration(seconds: retryCount * 2)); // 2, 4, 6 saniye bekle

        final statusUrl = Uri.parse(
          'https://istap-backend-1.onrender.com/api/checkPaymentStatus',
        );
        final statusBody = {
          'orderId': orderId,
          'transaction': transaction,
        };

        final statusResp = await http.post(
          statusUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(statusBody),
        );

        if (statusResp.statusCode == 200) {
          final statusData = jsonDecode(statusResp.body) as Map<String, dynamic>;
          debugPrint('Payment status response: $statusData');

          if (statusData['status'] == 'success') {
            // Ödeme gerçekten başarılı
            paymentActuallySucceeded = true;
            // Backend checkPaymentStatus içinde Firestore'u güncelledi
            isUpdated = true;
            break;
          } else if (statusData['status'] == 'error' || statusData['status'] == 'failed') {
            // Ödeme başarısız - retry yapma, çık
            debugPrint('Payment failed: ${statusData['message']}');
            paymentActuallySucceeded = false;
            break;
          }
        }
      } catch (e) {
        debugPrint('Error checking payment status (attempt $retryCount): $e');
      }
    }

    if (!mounted) return;

    // Loading'i kapat
    Navigator.of(context, rootNavigator: true).pop();

    setState(() => _isSubmitting = false);

    if (isUpdated) {
      // Başarılı - hem ödeme başarılı hem Firestore güncellendi
      _showSuccessDialog(isUrgent: true);
    } else if (paymentActuallySucceeded) {
      // Ödeme başarılı AMA Firestore güncellemesi başarısız
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.warning_rounded, color: Colors.orange, size: 60),
          title: const Text('Ödəniş Alındı'),
          content: const Text(
            'Ödənişiniz uğurla alındı, lakin elanınız hələ təcili olaraq işarələnməyib.\n\n'
            'Narahatlıq etməyin, elanınız 24 saat ərzində təcili olaraq işarələnəcək.\n\n'
            'Əgər problem davam edərsə, dəstək komandası ilə əlaqə saxlayın.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Anladım'),
              ),
            ),
          ],
        ),
      );
    }
    // Eğer paymentActuallySucceeded = false ise, hiçbir dialog gösterme
    // Kullanıcı zaten WebView'den hata mesajını gördü
  }

  void _showSuccessDialog({required bool isUrgent}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppTheme.successColor,
          size: 60,
        ),
        title: Text(
          widget.existingJob != null
              ? 'Elan redaktə edildi! 🎉'
              : isUrgent
                  ? 'Təcili Elan yerləşdirildi! 🔥'
                  : 'Elan yerləşdirildi! 🎉',
        ),
        content: Text(
          widget.existingJob != null
              ? 'Elanınız uğurla yeniləndi.'
              : isUrgent
                  ? 'Ödənişiniz uğurla tamamlandı!\nElanınız təcili olaraq $_urgentDays gün ərzində aktiv olacaq.'
                  : 'Elanınız uğurla yerləşdirildi.\n45 gün ərzində aktiv qalacaq.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Dialog'u kapat
                if (widget.existingJob != null) {
                  // Edit modunda: Önceki ekrana dön
                  Navigator.pop(context);
                } else {
                  // Yeni ilan modunda: Sadece formu temizle, pop etme (tab içindeyiz)
                  setState(() {
                    _formKey.currentState!.reset();
                    _titleController.clear();
                    _descriptionController.clear();
                    _salaryMinController.clear();
                    _salaryMaxController.clear();
                    _workingHoursController.clear();
                    _requirementController.clear();
                    _selectedBenefits.clear();
                    _requirements.clear();
                    _selectedLocation = null;
                    _selectedExperience = 'Təcrübəsiz';
                    _selectedEducation = 'Vacib deyil';
                    _isUrgent = false;
                    _urgentDays = null;
                    _companyLogoUrl = null;
                    _applicationMethod = 'in_app';
                    _externalUrlController.clear();
                    _allowCallIfAccepted = true;
                  });
                }
              },
              child: const Text('Tamam'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: context.scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingJob != null
                      ? 'Elanı Redaktə et'
                      : 'Yeni Elan ver',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.existingJob == null)
                  Text(
                    '1 dəqiqədə pulsuz Elan yerləşdir',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondaryColor,
                    ),
                  ),
                const SizedBox(height: 24),

                // Job Title
                _buildLabel('Vəzifə adı'),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'məs. Ofisant, Kuryer, Satıcı...',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Vəzifə adını daxil edin' : null,
                ),
                const SizedBox(height: 20),

                // Category
                _buildLabel('Kateqoriya'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.inputFillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                      items: JobCategories.all.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(c.icon, size: 18, color: c.color),
                              const SizedBox(width: 10),
                              Text(c.name),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Job Type
                _buildLabel('İş növü'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildJobTypeChip('Tam gün', 'fullTime'),
                    _buildJobTypeChip('Yarım gün', 'partTime'),
                    _buildJobTypeChip('Günlük', 'daily'),
                    _buildJobTypeChip('Saatlıq', 'hourly'),
                    _buildJobTypeChip('Freelance', 'freelance'),
                  ],
                ),
                const SizedBox(height: 20),

                // Education Level
                _buildLabel('Təhsil tələbi'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.inputFillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedEducation,
                      isExpanded: true,
                      onChanged: (v) => setState(() => _selectedEducation = v!),
                      items: const [
                        DropdownMenuItem(
                          value: 'Vacib deyil',
                          child: Text('Vacib deyil'),
                        ),
                        DropdownMenuItem(
                          value: 'Elmi dərəcə',
                          child: Text('Elmi dərəcə'),
                        ),
                        DropdownMenuItem(value: 'Ali', child: Text('Ali')),
                        DropdownMenuItem(
                          value: 'Natamam ali',
                          child: Text('Natamam ali'),
                        ),
                        DropdownMenuItem(
                          value: 'Orta texniki',
                          child: Text('Orta texniki'),
                        ),
                        DropdownMenuItem(
                          value: 'Orta xüsusi',
                          child: Text('Orta xüsusi'),
                        ),
                        DropdownMenuItem(value: 'Orta', child: Text('Orta')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Experience Level
                _buildLabel('İş Təcrübəsi'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.inputFillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedExperience,
                      isExpanded: true,
                      onChanged: (v) =>
                          setState(() => _selectedExperience = v!),
                      items: const [
                        DropdownMenuItem(
                          value: 'Təcrübəsiz',
                          child: Text('Təcrübəsiz'),
                        ),
                        DropdownMenuItem(
                          value: '1 ildən aşağı',
                          child: Text('1 ildən aşağı'),
                        ),
                        DropdownMenuItem(
                          value: '1 ildən 3 ilə qədər',
                          child: Text('1 ildən 3 ilə qədər'),
                        ),
                        DropdownMenuItem(
                          value: '3 ildən 5 ilə qədər',
                          child: Text('3 ildən 5 ilə qədər'),
                        ),
                        DropdownMenuItem(
                          value: '5 ildən artıq',
                          child: Text('5 ildən artıq'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Salary
                _buildLabel('Maaş (₼)'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _salaryMinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Minimum'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Maaş daxil edin' : null,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('—'),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _salaryMaxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Maksimum'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.inputFillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSalaryPeriod,
                          onChanged: (v) =>
                              setState(() => _selectedSalaryPeriod = v!),
                          items: const [
                            DropdownMenuItem(
                              value: 'aylıq',
                              child: Text('Aylıq'),
                            ),
                            DropdownMenuItem(
                              value: 'günlük',
                              child: Text('Günlük'),
                            ),
                            DropdownMenuItem(
                              value: 'saatlıq',
                              child: Text('Saatlıq'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Location
                _buildLabel('Şəhər'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.inputFillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      isExpanded: true,
                      onChanged: (v) => setState(() => _selectedCity = v!),
                      items: AppConstants.azerbaijanCities.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _buildLabel('İş yerinin mövqeyi *'),
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MapPickerScreen(initialLocation: _selectedLocation),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedLocation = result;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: context.inputFillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedLocation != null
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.map_rounded,
                          color: _selectedLocation != null
                              ? AppTheme.primaryColor
                              : context.textHintColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedLocation != null
                                ? 'Mövqe seçilib (${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)})'
                                : 'Xəritədə yeri seçin',
                            style: TextStyle(
                              color: _selectedLocation != null
                                  ? AppTheme.primaryColor
                                  : context.textHintColor,
                              fontWeight: _selectedLocation != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (_selectedLocation != null)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primaryColor,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Working Hours
                _buildLabel('İş saatı'),
                TextFormField(
                  controller: _workingHoursController,
                  decoration: const InputDecoration(
                    hintText: 'məs. 09:00 - 18:00',
                  ),
                ),
                const SizedBox(height: 20),

                // Requirements
                _buildLabel('Tələblər (namizəddən gözləntilər)'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _requirementController,
                        decoration: const InputDecoration(
                          hintText: 'məs. 1 il təcrübə, İngilis dili...',
                        ),
                        onFieldSubmitted: (v) => _addRequirement(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _addRequirement,
                        icon: const Icon(
                          Icons.add_rounded,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_requirements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _requirements.map((req) {
                      return Chip(
                        label: Text(req, style: const TextStyle(fontSize: 13)),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () {
                          setState(() {
                            _requirements.remove(req);
                          });
                        },
                        backgroundColor: context.scaffoldBackgroundColor,
                        side: BorderSide(
                          color: context.textHintColor.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),

                // Benefits
                _buildLabel('Yan haqlar (istəyə bağlı)'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableBenefits
                      .map((b) => _buildBenefitChip(b))
                      .toList(),
                ),
                const SizedBox(height: 20),

                // Description
                _buildLabel('İş haqqında ətraflı'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'İş barədə ətraflı məlumat yazın...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Açıqlama yazın' : null,
                ),
                const SizedBox(height: 20),

                // Company Logo (optional)
                _buildLabel('Şirkət logosu (istəyə bağlı)'),
                GestureDetector(
                  onTap: _isUploadingLogo ? null : _pickCompanyLogo,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: context.inputFillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _companyLogoUrl != null
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                      ),
                    ),
                    child: _isUploadingLogo
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              if (_companyLogoUrl != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _companyLogoUrl!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Logo yükləndi ✅',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: context.textHintColor,
                                  ),
                                  onPressed: () =>
                                      setState(() => _companyLogoUrl = null),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: context.textHintColor,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Qalereyadan logo seçin',
                                  style: TextStyle(
                                    color: context.textHintColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Urgent Switch - SADECE ZATEN ACİL OLMAYAN İLANLARDA GÖSTER
                if (widget.existingJob?.isUrgent != true) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.inputFillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isUrgent
                            ? AppTheme.accentColor
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Təcili Elan 🔥',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Elanınız axtarışlarda daha yuxarıda görünəcək',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 13,
                        ),
                      ),
                      value: _isUrgent,
                      activeColor: AppTheme.accentColor,
                      onChanged: (v) {
                        setState(() {
                          _isUrgent = v;
                          if (!_isUrgent) {
                            _urgentDays = null;
                          } else {
                            _urgentDays ??= 1;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isUrgent) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('1 gün • 0.01 AZN'),
                          selected: _urgentDays == 1,
                          onSelected: (_) => setState(() => _urgentDays = 1),
                        ),
                        ChoiceChip(
                          label: const Text('5 gün • 3 AZN'),
                          selected: _urgentDays == 5,
                          onSelected: (_) => setState(() => _urgentDays = 5),
                        ),
                        ChoiceChip(
                          label: const Text('10 gün • 5 AZN'),
                          selected: _urgentDays == 10,
                          onSelected: (_) => setState(() => _urgentDays = 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_urgentDays == null)
                      Text(
                        'Təcili gün sayını seçin',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                  ],
                  const SizedBox(height: 24),
                ],

                // Allow call if accepted toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _allowCallIfAccepted
                        ? AppTheme.successColor.withValues(alpha: 0.08)
                        : context.inputFillColor,
                    borderRadius: BorderRadius.circular(14),
                    border: _allowCallIfAccepted
                        ? Border.all(
                            color: AppTheme.successColor.withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      const Text('📞', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Qəbul etdiyin namizədlər sənə zəng edə bilsin',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _allowCallIfAccepted
                                  ? 'Namizəd qəbul edilsə zəng edə bilər'
                                  : 'Namizəd qəbul edilsə belə zəng edə bilməz',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textHintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _allowCallIfAccepted,
                        onChanged: (v) =>
                            setState(() => _allowCallIfAccepted = v),
                        activeColor: AppTheme.successColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Application method selector
                _buildLabel('Müraciət üsulu'),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.inputFillColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _applicationMethod = 'in_app'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _applicationMethod == 'in_app'
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Tətbiqdən',
                                style: TextStyle(
                                  color: _applicationMethod == 'in_app'
                                      ? Colors.white
                                      : context.textSecondaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _applicationMethod = 'redirect'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _applicationMethod == 'redirect'
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Yönləndir',
                                style: TextStyle(
                                  color: _applicationMethod == 'redirect'
                                      ? Colors.white
                                      : context.textSecondaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_applicationMethod == 'redirect') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _externalUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      hintText: 'https://example.com/apply',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    validator: (v) {
                      if (_applicationMethod == 'redirect' &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Yönləndirmə linkini daxil edin';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 28),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            widget.existingJob != null
                                ? 'Yadda Saxla'
                                : 'Elanı yerləşdir',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );

    // When editing, wrap in Scaffold (navigated directly, not as a tab)
    if (widget.existingJob != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Elanı Redaktə et'),
          centerTitle: true,
        ),
        body: content,
      );
    }

    // When creating (used as a tab), return without Scaffold.
    return content;
  }

  // Add requirement to the list
  void _addRequirement() {
    final text = _requirementController.text.trim();
    if (text.isNotEmpty && !_requirements.contains(text)) {
      setState(() {
        _requirements.add(text);
        _requirementController.clear();
      });
    }
  }

  Future<void> _pickCompanyLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isUploadingLogo = true);

    final url = await CloudinaryService.uploadImage(File(picked.path));

    if (url != null) {
      setState(() => _companyLogoUrl = url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo yüklənərkən xəta baş verdi.')),
        );
      }
    }

    if (mounted) setState(() => _isUploadingLogo = false);
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildJobTypeChip(String label, String value) {
    final isSelected = _selectedJobType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedJobType = value),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      backgroundColor: context.chipBackgroundColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : context.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildBenefitChip(String label) {
    final isSelected = _selectedBenefits.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          if (val) {
            _selectedBenefits.add(label);
          } else {
            _selectedBenefits.remove(label);
          }
        });
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      backgroundColor: context.chipBackgroundColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : context.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
    );
  }
}
