import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class JobCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const JobCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class JobCategories {
  static const List<JobCategory> all = [
    JobCategory(id: 'waiter', name: 'Ofisant', icon: Icons.restaurant, color: AppTheme.categoryFood),
    JobCategory(id: 'courier', name: 'Kuryer', icon: Icons.delivery_dining, color: AppTheme.categoryDelivery),
    JobCategory(id: 'sales', name: 'Satıcı', icon: Icons.storefront, color: AppTheme.categorySales),
    JobCategory(id: 'cleaner', name: 'Təmizlikçi', icon: Icons.cleaning_services, color: AppTheme.categoryCleaning),
    JobCategory(id: 'cook', name: 'Aşpaz', icon: Icons.soup_kitchen, color: AppTheme.categoryFood),
    JobCategory(id: 'security', name: 'Mühafizəçi', icon: Icons.security, color: AppTheme.categorySecurity),
    JobCategory(id: 'driver', name: 'Sürücü', icon: Icons.drive_eta, color: AppTheme.categoryDriver),
    JobCategory(id: 'cashier', name: 'Kassir', icon: Icons.point_of_sale, color: AppTheme.categorySales),
    JobCategory(id: 'warehouse', name: 'Anbardar', icon: Icons.warehouse, color: AppTheme.categoryOther),
    JobCategory(id: 'construction', name: 'Tikinti işçisi', icon: Icons.construction, color: AppTheme.warningColor),
    JobCategory(id: 'barista', name: 'Barista', icon: Icons.coffee, color: AppTheme.categoryFood),
    JobCategory(id: 'mechanic', name: 'Mexanik', icon: Icons.build, color: AppTheme.categoryOther),
    JobCategory(id: 'hairdresser', name: 'Bərbər', icon: Icons.content_cut, color: AppTheme.categoryCleaning),
    JobCategory(id: 'teacher', name: 'Müəllim', icon: Icons.school, color: AppTheme.infoColor),
    JobCategory(id: 'it', name: 'IT mütəxəssis', icon: Icons.computer, color: AppTheme.primaryColor),
    JobCategory(id: 'other', name: 'Digər', icon: Icons.work, color: AppTheme.categoryOther),
  ];

  static JobCategory getById(String id) {
    return all.firstWhere((c) => c.id == id, orElse: () => all.last);
  }
}

enum JobType {
  fullTime('Tam iş günü'),
  partTime('Yarım gün'),
  daily('Günlük'),
  hourly('Saatlıq'),
  freelance('Freelance'),
  urgent('Təcili');

  final String label;
  const JobType(this.label);
}

enum JobSortBy {
  newest('Ən yeni'),
  nearest('Ən yaxın'),
  highestPay('Ən yüksək maaş'),
  lowestPay('Ən aşağı maaş');

  final String label;
  const JobSortBy(this.label);
}
