import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  final bool isEmployerView;
  const ChatListScreen({super.key, this.isEmployerView = false});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Zəhmət olmasa daxil olun.'));
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  hintStyle: TextStyle(color: context.textHintColor, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: context.textHintColor, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          // Chat List
          Expanded(
            child: StreamBuilder(
              stream: ChatRepository().getUserChats(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Bir xəta baş verdi: ${snapshot.error}'));
                }

                final chats = snapshot.data ?? [];

                if (chats.isEmpty) {
                  return Center(
                    child: Text(
                      'Hazırda heç bir mesajınız yoxdur',
                      style: TextStyle(color: context.textHintColor, fontSize: 16),
                    ),
                  );
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<String> blockedUsers = [];
                    if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                      if (userData != null && userData.containsKey('blockedUsers')) {
                        blockedUsers = List<String>.from(userData['blockedUsers'] ?? []);
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
                          style: TextStyle(color: context.textHintColor, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filteredChats.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 78,
                        endIndent: 20,
                      ),
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        final bool isCurrentUserEmployer = currentUser.uid == chat.employerId;
                        final otherUserName = isCurrentUserEmployer
                            ? chat.jobSeekerName
                            : chat.employerName;
                        final otherUserId = isCurrentUserEmployer
                            ? chat.jobSeekerId
                            : chat.employerId;

                        final String formattedTime =
                            DateFormat('HH:mm').format(chat.updatedAt);
                        
                        final int unreadCount = chat.getUnreadCount(currentUser.uid);
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
                            child: const Icon(Icons.delete_rounded, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Diqqət', style: TextStyle(color: AppTheme.errorColor)),
                                content: const Text('Bu söhbəti silmək istədiyinizə əminsiniz? Sizin üçün həmişəlik silinəcək.'),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Ləğv et', style: TextStyle(color: context.textHintColor)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
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
                              await ChatRepository().hideChat(chat.id, currentUser.uid);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Söhbət silinərkən xəta baş verdi.')),
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
                              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                              builder: (context, userSnap) {
                                final userPhoto = (userSnap.data?.data() as Map<String, dynamic>?)?['photoUrl'] as String?;
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                                            otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
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
                                      fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                                      color: hasUnread ? context.textPrimaryColor : null,
                                    ),
                                  ),
                                ),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasUnread ? AppTheme.primaryColor : context.textHintColor,
                                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.lastMessage.isEmpty ? 'Müraciət qəbul edildi' : chat.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: hasUnread ? context.textPrimaryColor : context.textHintColor,
                                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (hasUnread)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
