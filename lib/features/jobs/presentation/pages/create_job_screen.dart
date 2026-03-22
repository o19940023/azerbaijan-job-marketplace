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

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

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
      if (job.isUrgent) _urgentDays = 1;
      _companyLogoUrl = job.companyLogo;
      _selectedEducation = job.educationLevel ?? 'Vacib deyil';
      _selectedExperience = job.experienceLevel ?? 'Təcrübəsiz';
      _allowCallIfAccepted = job.allowCallIfAccepted;
      _applicationMethod = job.applicationMethod;
      _externalUrlController.text = job.externalUrl ?? '';

      if (job.workingHours != null && job.workingHours!.contains(' - ')) {
        final parts = job.workingHours!.split(' - ');
        if (parts.length == 2) {
          final startParts = parts[0].split(':');
          final endParts = parts[1].split(':');
          if (startParts.length == 2 && endParts.length == 2) {
            _startTime = TimeOfDay(
              hour: int.tryParse(startParts[0]) ?? 9,
              minute: int.tryParse(startParts[1]) ?? 0,
            );
            _endTime = TimeOfDay(
              hour: int.tryParse(endParts[0]) ?? 18,
              minute: int.tryParse(endParts[1]) ?? 0,
            );
          }
        }
      }
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
      } catch (e) {}

      if (!mounted) return;

      final jobId =
          widget.existingJob?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final bool isEditingUrgentJob =
          widget.existingJob != null && widget.existingJob!.isUrgent;

      if (_isUrgent && _urgentDays != null && !isEditingUrgentJob) {
        await _handleUrgentPayment(jobId, currentUser.uid, companyName, phone);
      } else {
        await _saveJobToFirestore(
          jobId,
          currentUser.uid,
          companyName,
          phone,
          _isUrgent,
        );

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
      urgentUntil: widget.existingJob?.urgentUntil,
      urgentTransaction: widget.existingJob?.urgentTransaction,
    );

    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .set(newJob.toMap());
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
      await _saveJobToFirestore(jobId, employerId, companyName, phone, false);

      if (!mounted) return;

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

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
      final orderId = (data['order_id'] ?? '').toString();
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

      final paymentResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(url: redirectUrl),
        ),
      );

      if (!mounted) return;

      final verified = await _verifyAndUpdateUrgentStatus(
        jobId,
        orderId,
        transaction,
        days,
        paymentResult,
      );

      if (!verified && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              paymentResult == null
                  ? 'Ödəniş ləğv edildi.'
                  : paymentResult == false
                  ? 'Ödəniş uğursuz oldu.'
                  : 'Ödəniş təsdiqlənmədi.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
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

  Future<bool> _verifyAndUpdateUrgentStatus(
    String jobId,
    String orderId,
    String transaction,
    int days,
    bool? paymentResult,
  ) async {
    if (!mounted) return false;

    if (paymentResult == true) {
      try {
        final resp = await http.post(
          Uri.parse('https://istap-backend-1.onrender.com/api/manualConfirm'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'transaction': transaction,
            'orderId': orderId,
            'jobId': jobId,
            'days': days,
            'successRedirect': true,
          }),
        );

        if (!mounted) return false;

        bool ok = false;
        String? status;
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map<String, dynamic>) {
            ok = decoded['ok'] == true;
            status = decoded['status']?.toString();
          }
        } catch (_) {}

        if (!ok) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'not_confirmed'
                    ? 'Ödəniş təsdiqlənmədi.'
                    : 'Ödəniş hazırda təsdiqlənmir.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 6),
            ),
          );
          return false;
        }

        setState(() => _isSubmitting = false);
        _showSuccessDialog(isUrgent: true);
        return true;
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ödəniş təsdiqlənərkən xəta baş verdi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
    return false;
  }

  void _showSuccessDialog({required bool isUrgent}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppTheme.successColor,
          size: 64,
        ),
        title: Text(
          widget.existingJob != null
              ? 'Elan redaktə edildi! 🎉'
              : isUrgent
              ? 'Təcili Elan yerləşdirildi! 🔥'
              : 'Elan yerləşdirildi! 🎉',
          textAlign: TextAlign.center,
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
                Navigator.pop(ctx);
                if (widget.existingJob != null) {
                  Navigator.pop(context);
                } else {
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
                    _startTime = null;
                    _endTime = null;
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

  void _updateWorkingHours() {
    if (_startTime != null && _endTime != null) {
      final start =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
      final end =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
      _workingHoursController.text = '$start - $end';
    }
  }

  Future<void> _pickTime(bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 18, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _updateWorkingHours();
      });
    }
  }

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

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Material(
      color: context.scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────
                _buildPageHeader(isDark),
                const SizedBox(height: 24),

                // ── 1. Əsas Məlumatlar ──────────────────────
                _buildCard(
                  isDark: isDark,
                  icon: Icons.work_outline_rounded,
                  iconColor: const Color(0xFF6C63FF),
                  title: 'Əsas Məlumatlar',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Vəzifə adı'),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDeco(
                          hint: 'məs. Ofisant, Kuryer, Satıcı...',
                          isDark: isDark,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Vəzifə adını daxil edin' : null,
                      ),
                      const SizedBox(height: 18),
                      _label('Kateqoriya'),
                      _styledDropdown(
                        isDark: isDark,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            dropdownColor: isDark
                                ? const Color(0xFF1E1E2E)
                                : Colors.white,
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v!),
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
                      const SizedBox(height: 18),
                      _label('İş növü'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _jobTypeChip('Tam gün', 'fullTime', isDark),
                          _jobTypeChip('Yarım gün', 'partTime', isDark),
                          _jobTypeChip('Günlük', 'daily', isDark),
                          _jobTypeChip('Saatlıq', 'hourly', isDark),
                          _jobTypeChip('Freelance', 'freelance', isDark),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 2. Tələblər ─────────────────────────────
                _buildCard(
                  isDark: isDark,
                  icon: Icons.school_outlined,
                  iconColor: const Color(0xFF43B89C),
                  title: 'Namizəd Tələbləri',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Təhsil tələbi'),
                      _styledDropdown(
                        isDark: isDark,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedEducation,
                            isExpanded: true,
                            dropdownColor: isDark
                                ? const Color(0xFF1E1E2E)
                                : Colors.white,
                            onChanged: (v) =>
                                setState(() => _selectedEducation = v!),
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
                              DropdownMenuItem(
                                value: 'Orta',
                                child: Text('Orta'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _label('İş təcrübəsi'),
                      _styledDropdown(
                        isDark: isDark,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedExperience,
                            isExpanded: true,
                            dropdownColor: isDark
                                ? const Color(0xFF1E1E2E)
                                : Colors.white,
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
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 3. Maaş ─────────────────────────────────
                _buildCard(
                  isDark: isDark,
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Maaş',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Maaş aralığı (₼)'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _salaryMinController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDeco(
                                hint: 'Min',
                                isDark: isDark,
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Maaş daxil edin'
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '—',
                              style: TextStyle(
                                fontSize: 18,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _salaryMaxController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDeco(
                                hint: 'Maks',
                                isDark: isDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _styledDropdown(
                            isDark: isDark,
                            width: 100,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSalaryPeriod,
                                dropdownColor: isDark
                                    ? const Color(0xFF1E1E2E)
                                    : Colors.white,
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
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 4. Yer ──────────────────────────────────
                _buildCard(
                  isDark: isDark,
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Yer',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Şəhər'),
                      _styledDropdown(
                        isDark: isDark,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCity,
                            isExpanded: true,
                            dropdownColor: isDark
                                ? const Color(0xFF1E1E2E)
                                : Colors.white,
                            onChanged: (v) =>
                                setState(() => _selectedCity = v!),
                            items: AppConstants.azerbaijanCities.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label('İş yerinin mövqeyi *'),
                      _locationPicker(isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 5. İş Saatı ─────────────────────────────
                _buildCard(
                  isDark: isDark,
                  icon: Icons.schedule_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'İş Saatı',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('İş saatları (istəyə bağlı)'),
                      Row(
                        children: [
                          Expanded(child: _timePicker(true, isDark)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '—',
                              style: TextStyle(
                                fontSize: 18,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                          Expanded(child: _timePicker(false, isDark)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 6. Xüsusi Tələblər ──────────────────────
                _buildCard(
                  isDark: isDark,
                  icon: Icons.checklist_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Xüsusi Tələblər',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Namizəddən gözləntilər'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _requirementController,
                              decoration: _inputDeco(
                                hint: 'məs. 1 il təcrübə, İngilis dili...',
                                isDark: isDark,
                              ),
                              onFieldSubmitted: (_) => _addRequirement(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _addRequirement,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_requirements.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _requirements.map((req) {
                            return Chip(
                              label: Text(
                                req,
                                style: const TextStyle(fontSize: 13),
                              ),
                              deleteIcon:
                                  const Icon(Icons.close_rounded, size: 16),
                              onDeleted: () =>
                                  setState(() => _requirements.remove(req)),
                              backgroundColor: isDark
                                  ? const Color(0xFF2A2A3A)
                                  : const Color(0xFFF3F4F6),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF3A3A4A)
                                    : const Color(0xFFE5E7EB),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 7. Yan Haqlar ────────────────────────────
                _buildCard(
                  isDark: isDark,
                  icon: Icons.card_giftcard_outlined,
                  iconColor: const Color(0xFF10B981),
                  title: 'Yan Haqlar',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Əlavə imkanlar (istəyə bağlı)'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableBenefits
                            .map((b) => _benefitChip(b, isDark))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 8. Ətraflı Məlumat ───────────────────────
                _buildCard(
                  isDark: isDark,
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Ətraflı Məlumat',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('İş haqqında'),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: _inputDeco(
                          hint: 'İş barədə ətraflı məlumat yazın...',
                          isDark: isDark,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Açıqlama yazın' : null,
                      ),
                      const SizedBox(height: 18),
                      _label('Şirkət logosu (istəyə bağlı)'),
                      _logoPicker(isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── 9. Təcili Elan ───────────────────────────
                if (widget.existingJob?.isUrgent != true) ...[
                  _urgentSection(isDark),
                  const SizedBox(height: 14),
                ],

                // ── 10. Zəng İcazəsi ─────────────────────────
                _callPermissionCard(isDark),
                const SizedBox(height: 14),

                // ── 11. Müraciət Üsulu ───────────────────────
                _buildCard(
                  isDark: isDark,
                  icon: Icons.send_outlined,
                  iconColor: const Color(0xFF6C63FF),
                  title: 'Müraciət Üsulu',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Namizədlər necə müraciət etsin?'),
                      _applicationMethodToggle(isDark),
                      if (_applicationMethod == 'redirect') ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _externalUrlController,
                          keyboardType: TextInputType.url,
                          decoration: _inputDeco(
                            hint: 'https://example.com/apply',
                            isDark: isDark,
                          ).copyWith(
                            prefixIcon: const Icon(Icons.link_rounded),
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
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Submit Button ─────────────────────────────
                _submitButton(isDark),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.existingJob != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Elanı Redaktə et'),
          centerTitle: true,
        ),
        body: content,
      );
    }

    return content;
  }

  // ─────────────────────────────────────────
  //  UI HELPERS
  // ─────────────────────────────────────────

  Widget _buildPageHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.existingJob != null ? 'Elanı Redaktə et' : 'Yeni Elan ver',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: context.textPrimaryColor,
            letterSpacing: -0.5,
          ),
        ),
        if (widget.existingJob == null) ...[
          const SizedBox(height: 4),
          Text(
            '1 dəqiqədə pulsuz elan yerləşdir',
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2A3E)
              : const Color(0xFFEEEEEE),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(
            height: 24,
            color: isDark
                ? const Color(0xFF2A2A3E)
                : const Color(0xFFF3F4F6),
          ),
          child,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.textSecondaryColor,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  InputDecoration _inputDeco({required String hint, required bool isDark}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark ? const Color(0xFF13131F) : const Color(0xFFF9FAFB),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.errorColor),
      ),
    );
  }

  Widget _styledDropdown({
    required bool isDark,
    required Widget child,
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131F) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE5E7EB),
        ),
      ),
      child: child,
    );
  }

  Widget _locationPicker(bool isDark) {
    final isSelected = _selectedLocation != null;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<LatLng>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MapPickerScreen(initialLocation: _selectedLocation),
          ),
        );
        if (result != null) setState(() => _selectedLocation = result);
      },
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.08)
              : (isDark ? const Color(0xFF13131F) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.5)
                : (isDark
                    ? const Color(0xFF2A2A3E)
                    : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.map_rounded,
              size: 20,
              color: isSelected
                  ? AppTheme.primaryColor
                  : context.textHintColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isSelected
                    ? '📍  ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                    : 'Xəritədə mövqeyi seçin',
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : context.textHintColor,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _timePicker(bool isStart, bool isDark) {
    final time = isStart ? _startTime : _endTime;
    final label = isStart ? 'Başlanğıc' : 'Bitmə';

    return GestureDetector(
      onTap: () => _pickTime(isStart),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13131F) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: time != null
                ? AppTheme.primaryColor.withOpacity(0.4)
                : (isDark
                    ? const Color(0xFF2A2A3E)
                    : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 18,
              color:
                  time != null ? AppTheme.primaryColor : context.textHintColor,
            ),
            const SizedBox(width: 10),
            Text(
              time != null
                  ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                  : label,
              style: TextStyle(
                fontSize: 15,
                color: time != null
                    ? context.textPrimaryColor
                    : context.textHintColor,
                fontWeight:
                    time != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoPicker(bool isDark) {
    return GestureDetector(
      onTap: _isUploadingLogo ? null : _pickCompanyLogo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _companyLogoUrl != null
              ? AppTheme.primaryColor.withOpacity(0.07)
              : (isDark ? const Color(0xFF13131F) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _companyLogoUrl != null
                ? AppTheme.primaryColor.withOpacity(0.4)
                : (isDark
                    ? const Color(0xFF2A2A3E)
                    : const Color(0xFFE5E7EB)),
          ),
        ),
        child: _isUploadingLogo
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : Row(
                children: [
                  if (_companyLogoUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _companyLogoUrl!,
                        width: 38,
                        height: 38,
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
                        size: 20,
                      ),
                      onPressed: () => setState(() => _companyLogoUrl = null),
                    ),
                  ] else ...[
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: context.textHintColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Qalereyadan logo seçin',
                      style: TextStyle(color: context.textHintColor),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _urgentSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: _isUrgent
            ? const Color(0xFFFFF7ED)
            : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isUrgent
              ? const Color(0xFFF59E0B).withOpacity(0.5)
              : (isDark ? const Color(0xFF2A2A3E) : const Color(0xFFEEEEEE)),
          width: 1.5,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            title: Row(
              children: [
                Text(
                  'Təcili Elan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _isUrgent
                        ? const Color(0xFFD97706)
                        : context.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🔥', style: TextStyle(fontSize: 16)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Axtarışlarda daha yuxarıda görünəcək',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 13,
                ),
              ),
            ),
            value: _isUrgent,
            activeColor: const Color(0xFFF59E0B),
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
          if (_isUrgent) ...[
            Divider(
              height: 1,
              color: const Color(0xFFF59E0B).withOpacity(0.2),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Müddət seçin',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _urgentDayChip(1, '1 gün', '0.50 ₼'),
                      _urgentDayChip(5, '5 gün', '2.20 ₼'),
                      _urgentDayChip(10, '10 gün', '4.00 ₼'),
                    ],
                  ),
                  if (_urgentDays == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Gün sayını seçin',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _urgentDayChip(int days, String dayLabel, String price) {
    final isSelected = _urgentDays == days;
    return GestureDetector(
      onTap: () => setState(() => _urgentDays = days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B)
              : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD97706)
                : const Color(0xFFFDE68A),
          ),
        ),
        child: Column(
          children: [
            Text(
              dayLabel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? Colors.white : const Color(0xFF92400E),
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white.withOpacity(0.85)
                    : const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _callPermissionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _allowCallIfAccepted
            ? (isDark
                ? const Color(0xFF0D2016)
                : const Color(0xFFF0FDF4))
            : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _allowCallIfAccepted
              ? AppTheme.successColor.withOpacity(0.35)
              : (isDark
                  ? const Color(0xFF2A2A3E)
                  : const Color(0xFFEEEEEE)),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _allowCallIfAccepted
                  ? AppTheme.successColor.withOpacity(0.15)
                  : (isDark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.phone_outlined,
              color: _allowCallIfAccepted
                  ? AppTheme.successColor
                  : context.textHintColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qəbul edilən namizəd zəng edə bilsin',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _allowCallIfAccepted
                      ? 'Qəbul olunan namizəd zəng edə bilər'
                      : 'Zəng icazəsi verilmir',
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
            onChanged: (v) => setState(() => _allowCallIfAccepted = v),
            activeColor: AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _applicationMethodToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131F) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _methodTab('Tətbiqdən', 'in_app', isDark),
          _methodTab('Xaricə yönləndir', 'redirect', isDark),
        ],
      ),
    );
  }

  Widget _methodTab(String label, String value, bool isDark) {
    final isActive = _applicationMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _applicationMethod = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : context.textSecondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _submitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitJob,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.existingJob != null
                        ? Icons.save_rounded
                        : Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.existingJob != null ? 'Yadda Saxla' : 'Elanı Yerləşdir',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _jobTypeChip(String label, String value, bool isDark) {
    final isSelected = _selectedJobType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedJobType = value),
      selectedColor: AppTheme.primaryColor.withOpacity(0.12),
      backgroundColor:
          isDark ? const Color(0xFF13131F) : const Color(0xFFF3F4F6),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : context.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
    );
  }

  Widget _benefitChip(String label, bool isDark) {
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
      selectedColor: const Color(0xFF10B981).withOpacity(0.12),
      backgroundColor:
          isDark ? const Color(0xFF13131F) : const Color(0xFFF3F4F6),
      labelStyle: TextStyle(
        color: isSelected
            ? const Color(0xFF10B981)
            : context.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      checkmarkColor: const Color(0xFF10B981),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF10B981).withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
    );
  }
}