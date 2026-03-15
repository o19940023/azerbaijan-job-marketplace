import 'dart:io';
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

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

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
  final _availableBenefits = ['Yemək', 'Yol', 'Sığorta', 'Bonus/Prim', 'Nəqliyyat', 'Sərbəst qrafik'];
  bool _isUrgent = false;
  bool _isSubmitting = false;
  String? _companyLogoUrl;
  bool _isUploadingLogo = false;
  String _selectedEducation = 'Vacib deyil';
  String _selectedExperience = 'Təcrübəsiz';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _workingHoursController.dispose();
    _requirementController.dispose();
    super.dispose();
  }

  void _submitJob() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zəhmət olmasa xəritədən iş yerinin mövqeyini seçin.')),
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
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          companyName = data['fullName'] ?? 'Şirkət';
          phone = data['phone'] ?? '';
        }
      } catch (e) {
        // Ignored for fallback
      }

      if (!mounted) return;

      final newJob = JobModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        companyName: companyName, // Dynamic company name instead of Mocked one
        city: _selectedCity,
        district: '',
        salaryMin: double.tryParse(_salaryMinController.text) ?? 0,
        salaryMax: double.tryParse(_salaryMaxController.text),
        salaryPeriod: _selectedSalaryPeriod,
        jobType: _selectedJobType,
        workingHours: _workingHoursController.text.isNotEmpty ? _workingHoursController.text : null,
        address: null,
        description: _descriptionController.text,
        requirements: List.from(_requirements),
        benefits: List.from(_selectedBenefits),
        categoryId: _selectedCategory,
        employerId: currentUser.uid,
        isActive: true,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        contactPhone: phone,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 45)),
        companyLogo: _companyLogoUrl,
        educationLevel: _selectedEducation,
        experienceLevel: _selectedExperience,
      );

      await FirebaseFirestore.instance.collection('jobs').doc(newJob.id).set(newJob.toMap());

      setState(() => _isSubmitting = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.successColor,
            size: 60,
          ),
          title: const Text('Elan yerləşdirildi! 🎉'),
          content: const Text(
            'Elanınız uğurla yerləşdirildi.\n45 gün ərzində aktiv qalacaq.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
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
                },
                child: const Text('Tamam'),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yeni Elan ver',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimaryColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
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
                      DropdownMenuItem(value: 'Vacib deyil', child: Text('Vacib deyil')),
                      DropdownMenuItem(value: 'Elmi dərəcə', child: Text('Elmi dərəcə')),
                      DropdownMenuItem(value: 'Ali', child: Text('Ali')),
                      DropdownMenuItem(value: 'Natamam ali', child: Text('Natamam ali')),
                      DropdownMenuItem(value: 'Orta texniki', child: Text('Orta texniki')),
                      DropdownMenuItem(value: 'Orta xüsusi', child: Text('Orta xüsusi')),
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
                    onChanged: (v) => setState(() => _selectedExperience = v!),
                    items: const [
                      DropdownMenuItem(value: 'Təcrübəsiz', child: Text('Təcrübəsiz')),
                      DropdownMenuItem(value: '1 ildən aşağı', child: Text('1 ildən aşağı')),
                      DropdownMenuItem(value: '1 ildən 3 ilə qədər', child: Text('1 ildən 3 ilə qədər')),
                      DropdownMenuItem(value: '3 ildən 5 ilə qədər', child: Text('3 ildən 5 ilə qədər')),
                      DropdownMenuItem(value: '5 ildən artıq', child: Text('5 ildən artıq')),
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
                      validator: (v) => v == null || v.isEmpty
                          ? 'Maaş daxil edin'
                          : null,
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
                      decoration:
                          const InputDecoration(hintText: 'Maksimum'),
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
                              value: 'aylıq', child: Text('Aylıq')),
                          DropdownMenuItem(
                              value: 'günlük', child: Text('Günlük')),
                          DropdownMenuItem(
                              value: 'saatlıq', child: Text('Saatlıq')),
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
                      builder: (_) => MapPickerScreen(initialLocation: _selectedLocation),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Working Hours
              _buildLabel('İş saatı'),
              TextFormField(
                controller: _workingHoursController,
                decoration:
                    const InputDecoration(hintText: 'məs. 09:00 - 18:00'),
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
                      icon: const Icon(Icons.add_rounded, color: AppTheme.accentColor),
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
                      label: Text(
                        req,
                        style: const TextStyle(fontSize: 13),
                      ),
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
                children: _availableBenefits.map((b) => _buildBenefitChip(b)).toList(),
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
                validator: (v) => v == null || v.isEmpty
                    ? 'Açıqlama yazın'
                    : null,
              ),
              const SizedBox(height: 20),

              // Company Logo (optional)
              _buildLabel('Şirkət logosu (istəyə bağlı)'),
              GestureDetector(
                onTap: _isUploadingLogo ? null : _pickCompanyLogo,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)))
                      : Row(
                          children: [
                            if (_companyLogoUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(_companyLogoUrl!, width: 40, height: 40, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Logo yükləndi ✅', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                              ),
                              IconButton(
                                icon: Icon(Icons.close_rounded, color: context.textHintColor),
                                onPressed: () => setState(() => _companyLogoUrl = null),
                              ),
                            ] else ...[
                              Icon(Icons.add_photo_alternate_outlined, color: context.textHintColor),
                              const SizedBox(width: 12),
                              Text('Qalereyadan logo seçin', style: TextStyle(color: context.textHintColor)),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Urgent toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isUrgent
                      ? AppTheme.accentColor.withValues(alpha: 0.08)
                      : context.inputFillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: _isUrgent
                      ? Border.all(
                          color:
                              AppTheme.accentColor.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Təcili elan',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Elan ön sırada göstəriləcək',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textHintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isUrgent,
                      onChanged: (v) => setState(() => _isUrgent = v),
                      activeColor: AppTheme.accentColor,
                    ),
                  ],
                ),
              ),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Elanı yerləşdir',
                          style: TextStyle(
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
    );
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
