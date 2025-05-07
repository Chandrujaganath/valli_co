// lib/screens/messaging/messaging_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/messaging_service.dart';
import '../../services/user_service.dart';
import '../messaging/chat_screen.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen>
    with SingleTickerProviderStateMixin {
  late MessagingService messagingService;
  late UserService userService;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    messagingService = Provider.of<MessagingService>(context, listen: false);
    userService = Provider.of<UserService>(context, listen: false);
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startChat(UserModel peerUser) async {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    if (currentUser == null) {
      _showErrorSnackBar('User not available. Please try again.');
      return;
    }
    try {
      final chatId = await messagingService.getChatId(
        currentUser.userId,
        peerUser.userId,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatId: chatId, peerUser: peerUser),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error starting chat: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  Future<void> _selectUserToChat() async {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    if (currentUser == null) {
      _showErrorSnackBar('User not available. Please try again.');
      return;
    }

    try {
      final allUsers = await userService.getUsers();
      final otherUsers =
          allUsers.where((u) => u.userId != currentUser.userId).toList();

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 5,
                      width: 40,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Start a New Conversation',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for users...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: otherUsers.length,
                        itemBuilder: (context, index) {
                          final user = otherUsers[index];

                          if (_searchQuery.isNotEmpty &&
                              !user.name.toLowerCase().contains(_searchQuery) &&
                              !user.email
                                  .toLowerCase()
                                  .contains(_searchQuery)) {
                            return const SizedBox.shrink();
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade100,
                              backgroundImage: user.profilePhotoUrl.isNotEmpty
                                  ? NetworkImage(user.profilePhotoUrl)
                                  : null,
                              child: user.profilePhotoUrl.isEmpty
                                  ? Text(
                                      user.name.isEmpty
                                          ? '?'
                                          : user.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              user.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              user.role,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Chat',
                                style: GoogleFonts.poppins(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _startChat(user);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      _showErrorSnackBar('Error fetching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.user;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'User not logged in',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in again to access messages.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade800,
                Colors.deepPurple.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<QuerySnapshot>(
          stream: messagingService.getUserChats(currentUser.userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your conversations...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final chats = snapshot.data!.docs;

            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat,
                        size: 60,
                        color: Colors.deepPurple.shade300,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No conversations yet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start chatting with your colleagues!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _selectUserToChat,
                      icon: const Icon(Icons.add),
                      label: Text(
                        'New Conversation',
                        style: GoogleFonts.poppins(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Filter chats based on search query if needed
            List<QueryDocumentSnapshot> filteredChats = chats;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                final chatData =
                    filteredChats[index].data() as Map<String, dynamic>;
                final participants =
                    List<String>.from(chatData['participants']);
                final peerId = participants.firstWhere(
                  (id) => id != currentUser.userId,
                  orElse: () => '',
                );

                if (peerId.isEmpty) return const SizedBox();

                return FutureBuilder<UserModel?>(
                  future: userService.getUserById(peerId),
                  builder: (context, peerSnapshot) {
                    if (!peerSnapshot.hasData) {
                      return const ChatListSkeleton();
                    }

                    final peerUser = peerSnapshot.data!;

                    // Filter by search query
                    if (_searchQuery.isNotEmpty &&
                        !peerUser.name.toLowerCase().contains(_searchQuery)) {
                      return const SizedBox.shrink();
                    }

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: messagingService
                          .getLastMessage(filteredChats[index].id),
                      builder: (context, lastMessageSnapshot) {
                        String lastMessageText = 'Start a conversation';
                        String lastMessageTime = '';

                        if (lastMessageSnapshot.hasData &&
                            lastMessageSnapshot.data != null) {
                          final lastMessage = lastMessageSnapshot.data!;

                          if (lastMessage.containsKey('deleted') &&
                              lastMessage['deleted'] == true) {
                            lastMessageText = 'Message was deleted';
                          } else if (lastMessage.containsKey('imageUrl') &&
                              lastMessage['imageUrl'] != null &&
                              lastMessage['imageUrl'].isNotEmpty) {
                            lastMessageText = '📷 Photo';
                          } else if (lastMessage.containsKey('audioUrl') &&
                              lastMessage['audioUrl'] != null &&
                              lastMessage['audioUrl'].isNotEmpty) {
                            lastMessageText = '🎤 Voice Message';
                          } else if (lastMessage.containsKey('text')) {
                            lastMessageText = lastMessage['text'];
                          }

                          if (lastMessage.containsKey('timestamp') &&
                              lastMessage['timestamp'] != null) {
                            final timestamp =
                                lastMessage['timestamp'] as Timestamp;
                            final date = timestamp.toDate();
                            final now = DateTime.now();

                            if (date.year == now.year &&
                                date.month == now.month &&
                                date.day == now.day) {
                              // Today - show time only
                              lastMessageTime =
                                  DateFormat('h:mm a').format(date);
                            } else if (date.year == now.year &&
                                date.month == now.month &&
                                date.day == now.day - 1) {
                              // Yesterday
                              lastMessageTime = 'Yesterday';
                            } else if (date.isAfter(
                                now.subtract(const Duration(days: 7)))) {
                              // Within a week - show day name
                              lastMessageTime = DateFormat('EEEE').format(date);
                            } else {
                              // Older - show date
                              lastMessageTime =
                                  DateFormat('MMM d').format(date);
                            }
                          }
                        }

                        return ChatListTile(
                          peerUser: peerUser,
                          lastMessage: lastMessageText,
                          lastMessageTime: lastMessageTime,
                          onTap: () => _startChat(peerUser),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectUserToChat,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.chat),
      ),
    );
  }
}

class ChatListTile extends StatelessWidget {
  final UserModel peerUser;
  final String lastMessage;
  final String lastMessageTime;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.peerUser,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.deepPurple.shade100,
                    backgroundImage: peerUser.profilePhotoUrl.isNotEmpty
                        ? NetworkImage(peerUser.profilePhotoUrl)
                        : null,
                    child: peerUser.profilePhotoUrl.isEmpty
                        ? Text(
                            peerUser.name.isEmpty
                                ? '?'
                                : peerUser.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: peerUser.isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          peerUser.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (lastMessageTime.isNotEmpty)
                          Text(
                            lastMessageTime,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
