import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/chat_repository.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  late final String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Çat açıldıqda oxunmamış mesajları sıfırla
    if (currentUserId.isNotEmpty) {
      ChatRepository().markAsRead(widget.chatId, currentUserId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUserId.isEmpty) return;

    _messageController.clear();

    try {
      await ChatRepository().sendMessage(widget.chatId, currentUserId, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Səhv baş verdi: $e')));
      }
    }
  }

  void _showReportDialog() {
    String selectedReason = 'Spam';
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Şikayət Et',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Zəhmət olmasa şikayət səbəbini seçin:'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      items: const [
                        DropdownMenuItem(
                          value: 'Spam',
                          child: Text('Spam və ya Reklam'),
                        ),
                        DropdownMenuItem(
                          value: 'Təhqiramiz məzmun',
                          child: Text('Təhqiramiz məzmun'),
                        ),
                        DropdownMenuItem(
                          value: 'Saxtakarlıq',
                          child: Text('Saxtakarlıq / Fırıldaqçılıq'),
                        ),
                        DropdownMenuItem(value: 'Digər', child: Text('Digər')),
                      ],
                      onChanged: (val) {
                        setState(() => selectedReason = val!);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: detailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Əlavə məlumat (İstəyə bağlı)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Ləğv et',
                    style: TextStyle(color: context.textHintColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog

                    try {
                      await ChatRepository().submitReport(
                        reporterId: currentUserId,
                        targetId: widget.otherUserId,
                        targetType: 'user',
                        reason: selectedReason,
                        additionalDetails: detailsController.text.trim(),
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Şikayətiniz uğurla göndərildi. Komandamız tərəfindən 24 saat ərzində baxılacaq.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Şikayət göndərilərkən xəta baş verdi.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Göndər'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'İstifadəçini Blokla',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        content: const Text(
          'Bu istifadəçini bloklamaq istədiyinizə əminsiniz? O sizə bir daha mesaj yaza bilməyəcək və elanlarınızı görməyəcək.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ləğv et',
              style: TextStyle(color: context.textHintColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              try {
                // Blokla
                await ChatRepository().toggleBlockUser(
                  currentUserId,
                  widget.otherUserId,
                  true,
                );

                // Şəxsin çatını hazırkı istifadəçi üçün gizlət
                await ChatRepository().hideChat(widget.chatId, currentUserId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('İstifadəçi bloklandı.')),
                  );
                  Navigator.pop(context); // Leave chat screen
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xəta baş verdi.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Blokla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        title: Row(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.otherUserId)
                  .get(),
              builder: (context, snap) {
                final photoUrl =
                    (snap.data?.data() as Map<String, dynamic>?)?['photoUrl']
                        as String?;
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    image: photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photoUrl == null
                      ? Center(
                          child: Text(
                            widget.otherUserName.isNotEmpty
                                ? widget.otherUserName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'report') {
                _showReportDialog();
              } else if (value == 'block') {
                _showBlockConfirmation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(
                      Icons.report_problem_outlined,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('Şikayət et'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(
                      Icons.block_flipped,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('İstifadəçini blokla'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Safety Tip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppTheme.warningColor.withValues(alpha: 0.05),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Təhqiramiz və ya kobud mesajlar göndərmək qadağandır.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Messages List
          Expanded(
            child: StreamBuilder(
              stream: ChatRepository().getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Bilinməyən xəta: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Söhbətə başlayın.',
                      style: TextStyle(color: context.textHintColor),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // Auto-scroll to bottom behavior
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUserId;
                    final timeString = DateFormat(
                      'HH:mm',
                    ).format(msg.createdAt);

                    return _MessageBubble(
                      messageId: msg.id,
                      chatId: widget.chatId,
                      text: msg.text,
                      isMe: isMe,
                      time: timeString,
                    );
                  },
                );
              },
            ),
          ),
          // Input Field
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              8,
              MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: context.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: context.isDarkMode
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.inputFillColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Mesaj yazın...',
                        hintStyle: TextStyle(
                          color: context.textHintColor,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String messageId;
  final String chatId;
  final String text;
  final bool isMe;
  final String time;

  const _MessageBubble({
    required this.messageId,
    required this.chatId,
    required this.text,
    required this.isMe,
    required this.time,
  });

  void _confirmDeleteMessage(BuildContext context) {
    if (!isMe) return; // Only allow deleting own messages

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Mesajı sil',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        content: const Text('Bu mesajı silmək istədiyinizə əminsiniz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ləğv et',
              style: TextStyle(color: context.textHintColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await ChatRepository().deleteMessage(chatId, messageId);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mesaj silinərkən xəta baş verdi.'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe ? () => _confirmDeleteMessage(context) : null,
        child: Container(
          margin: EdgeInsets.only(
            bottom: 8,
            left: isMe ? 60 : 0,
            right: isMe ? 0 : 60,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryColor : context.inputFillColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isMe ? Colors.white : context.textPrimaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.6)
                      : context.textHintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
