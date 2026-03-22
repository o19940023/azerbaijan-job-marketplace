import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/cloudinary_service.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}
class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();
  
  String? _selectedCity;
  String? _selectedGender;
  DateTime? _birthDate;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;
  String _userType = 'job_seeker';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? user.email ?? '';
          _bioController.text = data['bio'] ?? '';
          _experienceController.text = data['experience'] ?? '';
          _educationController.text = data['education'] ?? '';
          _skillsController.text = data['skills'] ?? '';
          
          final dobTimestamp = data['birthDate'];
          if (dobTimestamp is Timestamp) {
            _birthDate = dobTimestamp.toDate();
          }
          // Normalize gender value to match dropdown items
          final gender = data['gender'];
          if (gender != null) {
            final genderLower = gender.toString().toLowerCase();
            if (genderLower == 'kişi') {
              _selectedGender = 'Kişi';
            } else if (genderLower == 'qadın') {
              _selectedGender = 'Qadın';
            } else if (genderLower.contains('qeyd') || genderLower.contains('istəmir')) {
              _selectedGender = 'Qeyd etmək istəmirəm';
            } else {
              _selectedGender = gender;
            }
          }

          final city = data['city'];
          if (city != null && AppConstants.azerbaijanCities.contains(city)) {
            _selectedCity = city;
          } else {
            _selectedCity = AppConstants.azerbaijanCities.first;
          }
          
          _userType = data['userType'] ?? 'job_seeker';
          _photoUrl = data['photoUrl'];
          _isLoading = false;
        });
        return;
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);

    final imageFile = File(picked.path);
    final url = await CloudinaryService.uploadImage(imageFile);

    if (url != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'photoUrl': url,
        });
        setState(() => _photoUrl = url);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şəkil yüklənərkən xəta baş verdi.')),
        );
      }
    }

    if (mounted) setState(() => _isUploadingPhoto = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili redaktə et'),
        leading: Navigator.canPop(context) 
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_rounded),
              )
            : null,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: _photoUrl == null ? AppTheme.primaryGradient : null,
                      shape: BoxShape.circle,
                      image: _photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _isUploadingPhoto
                        ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : _photoUrl == null
                            ? const Icon(Icons.person_rounded, size: 50, color: Colors.white)
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accentColor, AppTheme.primaryColor],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
            const SizedBox(height: 32),

            // Basic Info Section
            _buildSectionCard(
              context,
              title: 'Əsas Məlumatlar',
              icon: Icons.person_outline_rounded,
              children: [
                _buildLabel(_userType == 'employer' ? 'Ad və ya Şirkət Adı' : 'Ad və Soyad'),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: _userType == 'employer' ? 'Şirkət adı və ya Ad Soyad' : 'Ad Soyad',
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('Telefon'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Telefon nömrəsi',
                    prefixText: '+994 ',
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('Email (istəyə bağlı)'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'email@example.com'),
                ),
                const SizedBox(height: 16),
                _buildLabel('Şəhər'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.inputFillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity ?? AppConstants.azerbaijanCities.first,
                      isExpanded: true,
                      onChanged: (v) => setState(() => _selectedCity = v!),
                      items: AppConstants.azerbaijanCities
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),

            if (_userType == 'job_seeker') ...[
              const SizedBox(height: 16),
              _buildSectionCard(
                context,
                title: 'Şəxsi Məlumatlar',
                icon: Icons.info_outline_rounded,
                children: [
                  _buildLabel('Doğum Tarixi'),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _birthDate ?? DateTime(2000),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _birthDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: context.inputFillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _birthDate == null
                                ? 'Seçin'
                                : DateFormat('dd.MM.yyyy').format(_birthDate!),
                            style: TextStyle(
                              color: _birthDate == null ? context.textHintColor : context.textPrimaryColor,
                            ),
                          ),
                          Icon(Icons.calendar_today_rounded, color: context.textHintColor, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Cinsiyyət'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.inputFillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        hint: const Text('Seçin'),
                        isExpanded: true,
                        onChanged: (v) => setState(() => _selectedGender = v),
                        items: ['Kişi', 'Qadın', 'Qeyd etmək istəmirəm']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                context,
                title: 'Peşəkar Məlumatlar',
                icon: Icons.work_outline_rounded,
                children: [
                  _buildLabel('Təcrübə'),
                  TextFormField(
                    controller: _experienceController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Məs: 3 il ofisant kimi çalışmışam'),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Təhsil'),
                  TextFormField(
                    controller: _educationController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Məs: ADNSU, Bakalavr'),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Bacarıqlar'),
                  TextFormField(
                    controller: _skillsController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Məs: Ünsiyyət, komanda işi'),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Haqqımda'),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Özünüz haqqında qısa məlumat...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  setState(() => _isSaving = true);
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final updates = <String, dynamic>{
                      'fullName': _nameController.text,
                      'phone': _phoneController.text,
                      'email': _emailController.text,
                      'city': _selectedCity,
                    };

                    if (_userType == 'job_seeker') {
                      updates['bio'] = _bioController.text;
                      updates['experience'] = _experienceController.text;
                      updates['education'] = _educationController.text;
                      updates['skills'] = _skillsController.text;
                      if (_birthDate != null) {
                        updates['birthDate'] = Timestamp.fromDate(_birthDate!);
                      }
                      if (_selectedGender != null) {
                        updates['gender'] = _selectedGender;
                      }
                    }

                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil yeniləndi ✅'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                      
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(
                          context, 
                          _userType == 'employer' ? AppRouter.employerHome : AppRouter.jobSeekerHome
                        );
                      }
                    }
                  }
                  if (mounted) setState(() => _isSaving = false);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Yadda saxla',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
