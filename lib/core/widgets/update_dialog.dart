import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_config_service.dart';
import '../widgets/custom_button.dart';

class UpdateDialog extends StatelessWidget {
  final bool isMandatory;
  const UpdateDialog({super.key, this.isMandatory = true});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMandatory ? Icons.system_update_rounded : Icons.update_rounded,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isMandatory ? 'Yeni Yeniləmə Mövcuddur' : 'Yeniləmə Mövcuddur',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isMandatory
                    ? 'Tətbiqin yeni versiyası artıq mağazada mövcuddur. Davam etmək üçün lütfən tətbiqi yeniləyin.'
                    : 'Tətbiqin yeni versiyası mövcuddur. Yeniləyərək ən yeni özəlliklərdən istifadə edə bilərsiniz.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'İndi Yenilə',
                width: double.infinity,
                onPressed: () async {
                  final String url = Platform.isAndroid
                      ? RemoteConfigService().getAndroidStoreUrl()
                      : RemoteConfigService().getIosStoreUrl();
                  
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                },
              ),
              if (!isMandatory) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Sonra',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showUpdateDialog(BuildContext context, {bool isMandatory = true}) async {
  return showDialog(
    context: context,
    barrierDismissible: !isMandatory,
    builder: (context) => UpdateDialog(isMandatory: isMandatory),
  );
}
