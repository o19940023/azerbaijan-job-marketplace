import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  final bool isEmployerView;
  const ChatListScreen({super.key, this.isEmployerView = false});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      _checkChatEula();
    }
  }

  Future<void> _checkChatEula() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('chat_eula_accepted') ?? false;

    if (!accepted && mounted) {
      _showEulaDialog();
    }
  }

  void _showEulaDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text('İstifadə Qaydaları'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hörmətli istifadəçi, mesajlaşma bölməsindən istifadə etmək üçün aşağıdakı qaydalarla razılaşmağınız mütləqdir:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildRuleItem(
                'Hörmətli davranın: Digər istifadəçilərə qarşı təhqiramiz və ya kobud ifadələrdən çəkinin.',
              ),
              _buildRuleItem(
                'Düzgünlük: Yalnız doğru və dürüst məlumatlar paylaşın.',
              ),
              _buildRuleItem(
                'Məxfilik: Şəxsi məlumatlarınızı paylaşarkən diqqətli olun.',
              ),
              _buildRuleItem(
                'Şikayət: Qaydaları pozan istifadəçiləri "Şikayət et" düyməsi ilə bizə bildirin.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Apple və Google qaydalarına əsasən, təhqiramiz məzmun paylaşan istifadəçilər sistemdən həmişəlik uzaqlaşdırılacaqdır.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final Uri url = Uri.parse(
                    'https://istapapp.netlify.app/terms.html',
                  );
                  if (!await launchUrl(url)) {
                    debugPrint('Could not launch $url');
                  }
                },
                child: const Text(
                  'Tam İstifadəçi Şərtləri (EULA)',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('chat_eula_accepted', true);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Razıyam və Qəbul edirəm',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      final userType = widget.isEmployerView ? 'employer' : 'job_seeker';
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Zəhmət olmasa daxil olun.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.authChoice,
                      arguments: userType,
                    );
                  },
                  child: const Text('Daxil ol / Qeydiyyat'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Safety Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              border: const Border(
                bottom: BorderSide(color: AppTheme.warningColor, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.security_rounded,
                  size: 16,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zəhmət olmasa qarşı tərəfə qarşı hörmətli davranın. Şikayət edilən hesablar dərhal bağlanacaq.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'Mesajlar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
              ),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: context.inputFillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Mesajlarda axtar...',
                  hintStyle: TextStyle(
                    color: context.textHintColor,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.textHintColor,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          // Chats list
          Expanded(
            child: StreamBuilder(
              stream: ChatRepository().getUserChats(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Bir xəta baş verdi: ${snapshot.error}'),
                  );
                }

                final chats = snapshot.data ?? [];

                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 80,
                          color: context.textHintColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hələ heç bir mesajınız yoxdur',
                          style: TextStyle(
                            fontSize: 16,
                            color: context.textHintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İş elanlarına müraciət edərək söhbətə başlaya bilərsiniz',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textHintColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<String> blockedUsers = [];
                    if (userSnapshot.hasData &&
                        userSnapshot.data != null &&
                        userSnapshot.data!.exists) {
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>?;
                      if (userData != null &&
                          userData.containsKey('blockedUsers')) {
                        blockedUsers = List<String>.from(
                          userData['blockedUsers'] ?? [],
                        );
                      }
                    }

                    final filteredChats = chats.where((chat) {
                      final otherUserId = chat.participantIds.firstWhere(
                        (id) => id != currentUser.uid,
                        orElse: () => '',
                      );
                      return !blockedUsers.contains(otherUserId);
                    }).toList();

                    if (filteredChats.isEmpty) {
                      return Center(
                        child: Text(
                          'Hazırda heç bir mesajınız yoxdur',
                          style: TextStyle(
                            color: context.textHintColor,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filteredChats.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 78, endIndent: 20),
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        final bool isCurrentUserEmployer =
                            currentUser.uid == chat.employerId;
                        final otherUserName = isCurrentUserEmployer
                            ? chat.jobSeekerName
                            : chat.employerName;
                        final otherUserId = isCurrentUserEmployer
                            ? chat.jobSeekerId
                            : chat.employerId;

                        final String formattedTime = DateFormat(
                          'HH:mm',
                        ).format(chat.updatedAt);

                        final int unreadCount = chat.getUnreadCount(
                          currentUser.uid,
                        );
                        final bool hasUnread = unreadCount > 0;

                        return Dismissible(
                          key: Key(chat.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'Diqqət',
                                  style: TextStyle(color: AppTheme.errorColor),
                                ),
                                content: const Text(
                                  'Bu söhbəti silmək istədiyinizə əminsiniz? Sizin üçün həmişəlik silinəcək.',
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      'Ləğv et',
                                      style: TextStyle(
                                        color: context.textHintColor,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.errorColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Sil'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            try {
                              await ChatRepository().hideChat(
                                chat.id,
                                currentUser.uid,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Söhbət silinərkən xəta baş verdi.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(otherUserId)
                                  .get(),
                              builder: (context, userSnap) {
                                final userPhoto =
                                    (userSnap.data?.data()
                                            as Map<
                                              String,
                                              dynamic
                                            >?)?['photoUrl']
                                        as String?;
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                    image: userPhoto != null
                                        ? DecorationImage(
                                            image: NetworkImage(userPhoto),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: userPhoto == null
                                      ? Center(
                                          child: Text(
                                            otherUserName.isNotEmpty
                                                ? otherUserName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    otherUserName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: hasUnread
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: hasUnread
                                          ? context.textPrimaryColor
                                          : null,
                                    ),
                                  ),
                                ),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasUnread
                                        ? AppTheme.primaryColor
                                        : context.textHintColor,
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.lastMessage.isEmpty
                                        ? 'Müraciət qəbul edildi'
                                        : chat.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: hasUnread
                                          ? context.textPrimaryColor
                                          : context.textHintColor,
                                      fontWeight: hasUnread
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (hasUnread)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    chatId: chat.id,
                                    otherUserName: otherUserName,
                                    otherUserId: otherUserId,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
