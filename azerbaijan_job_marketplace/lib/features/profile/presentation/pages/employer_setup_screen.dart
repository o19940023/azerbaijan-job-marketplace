import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';

class EmployerSetupScreen extends StatefulWidget {
  const EmployerSetupScreen({super.key});

  @override
  State<EmployerSetupScreen> createState() => _EmployerSetupScreenState();
}

class _EmployerSetupScreenState extends State<EmployerSetupScreen> {
  final _companyNameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _industryController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _regNumberController.dispose();
    _industryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_companyNameController.text.isEmpty || _regNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zəhmət olmasa vacib xanaları (Şirkət Adı və VÖEN) doldurun')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'companyName': _companyNameController.text,
          'regNumber': _regNumberController.text,
          'sector': _industryController.text,
          'companyAddress': _addressController.text,
          'fullName': _companyNameController.text,
        });
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.employerHome, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xəta baş verdi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Şirkət Məlumatları'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hesabınız yaradıldı! İndi isə şirkətinizin məlumatlarını daxil edin.',
                style: TextStyle(
                  fontSize: 16,
                  color: context.textSecondaryColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Mock Logo Upload UI
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.add_photo_alternate_rounded, size: 40, color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Loqo yüklə', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 32),
              
              TextField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Şirkət Adı *',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _regNumberController,
                decoration: const InputDecoration(
                  labelText: 'VÖEN *',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _industryController,
                decoration: const InputDecoration(
                  labelText: 'Sektor / Sənaye',
                  hintText: 'Məs: İT, Logistika, Restoran',
                  prefixIcon: Icon(Icons.work_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ünvan',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const SizedBox(
                      width: 24, height: 24, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text('Məlumatları Yadda Saxla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
