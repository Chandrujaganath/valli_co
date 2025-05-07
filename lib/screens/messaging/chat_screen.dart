// lib/screens/messaging/chat_screen.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/messaging_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel peerUser;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.peerUser,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  bool _isLoading = false;
  bool _isRecorderInitialized = false;
  bool _isSendingMedia = false;
  bool _isTyping = false;
  Timer? _typingTimer;

  // Audio player
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlayerInit = false;
  bool _isPlaying = false;
  Duration _currentPos = Duration.zero;
  Duration _totalDur = Duration.zero;
  String? _playingUrl; // the audioUrl currently playing
  StreamSubscription? _playerSub;

  // Recording states
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  StreamSubscription? _recorderSub;

  // Animation controllers
  late AnimationController _sendButtonController;
  late AnimationController _typingIndicatorController;

  late MessagingService _messagingService;
  late UserService _userService;
  String? _currentUserId;

  // Peer presence
  Stream<DocumentSnapshot>? _peerStatusStream;
  bool _isPeerOnline = false;
  String? _peerLastSeen;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initRecorder();
    _initPlayer();

    // Initialize typing timer
    _messageController.addListener(_onTextChanged);
  }

  void _initAnimations() {
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _typingIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  void _onTextChanged() {
    final isCurrentlyTyping = _messageController.text.isNotEmpty;

    if (isCurrentlyTyping != _isTyping) {
      setState(() {
        _isTyping = isCurrentlyTyping;
      });

      if (isCurrentlyTyping) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }

    // Reset the timer on each text change
    _typingTimer?.cancel();
    if (_currentUserId != null && isCurrentlyTyping) {
      // Notify backend that user is typing (optional)
      _typingTimer = Timer(const Duration(seconds: 2), () {
        // Stop typing indicator after 2 seconds of inactivity
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messagingService = Provider.of<MessagingService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);

    // Setup peer presence stream
    _peerStatusStream ??= FirebaseFirestore.instance
        .collection('users')
        .doc(widget.peerUser.userId)
        .snapshots();

    // Listen to peer status updates
    _peerStatusStream?.listen(_updatePeerStatus);

    // Mark messages as read when chat opens
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    if (currentUser != null && _currentUserId == null) {
      _currentUserId = currentUser.userId;
      _userService.setUserOnline(_currentUserId!);
      _messagingService.markMessagesAsRead(widget.chatId, _currentUserId!);
    }
  }

  void _updatePeerStatus(DocumentSnapshot snapshot) {
    if (!mounted) return;

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>?;
      final isOnline = data?['isOnline'] ?? false;

      setState(() {
        _isPeerOnline = isOnline;

        if (!isOnline && data?['lastSeen'] != null) {
          final lastSeen = data!['lastSeen'];
          if (lastSeen is Timestamp) {
            final lastSeenDate = lastSeen.toDate();
            final now = DateTime.now();

            if (lastSeenDate.day == now.day &&
                lastSeenDate.month == now.month &&
                lastSeenDate.year == now.year) {
              // Today
              _peerLastSeen =
                  'Last seen today at ${DateFormat('h:mm a').format(lastSeenDate)}';
            } else if (lastSeenDate
                .isAfter(now.subtract(const Duration(days: 1)))) {
              // Yesterday
              _peerLastSeen =
                  'Last seen yesterday at ${DateFormat('h:mm a').format(lastSeenDate)}';
            } else {
              // Other days
              _peerLastSeen =
                  'Last seen on ${DateFormat('MMM d').format(lastSeenDate)}';
            }
          } else {
            _peerLastSeen = 'Last seen recently';
          }
        } else {
          _peerLastSeen = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _recorderSub?.cancel();
    _audioRecorder.closeRecorder();

    _playerSub?.cancel();
    _player.closePlayer();

    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _sendButtonController.dispose();
    _typingIndicatorController.dispose();

    // Set user offline if navigating away (optional)
    if (_currentUserId != null) {
      _userService.setUserOffline(_currentUserId!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current user from provider
    final user = context.watch<UserProvider>().user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.peerUser.name)),
        body:
            const Center(child: Text("User not logged in or still loading...")),
      );
    }
    if (_currentUserId == null) {
      _currentUserId = user.userId;
      _userService.setUserOnline(_currentUserId!);
      _messagingService.markMessagesAsRead(widget.chatId, _currentUserId!);
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _buildMessagesList(),
                    if (_isLoading || _isSendingMedia)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          color: Colors.deepPurple.shade300,
                        ),
                      ),
                  ],
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      title: InkWell(
        onTap: () {
          // Optional: show user profile or details
        },
        customBorder: const CircleBorder(),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.deepPurple.shade100,
                    backgroundImage: widget.peerUser.profilePhotoUrl.isNotEmpty
                        ? NetworkImage(widget.peerUser.profilePhotoUrl)
                        : null,
                    child: widget.peerUser.profilePhotoUrl.isEmpty
                        ? Text(
                            widget.peerUser.name.isEmpty
                                ? '?'
                                : widget.peerUser.name[0].toUpperCase(),
                            style: const TextStyle(
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
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isPeerOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.peerUser.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isPeerOnline)
                    Text(
                      'Online',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    )
                  else if (_peerLastSeen != null)
                    Text(
                      _peerLastSeen!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showChatOptions,
        ),
      ],
      backgroundColor: Colors.deepPurple,
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              width: 40,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.deepPurple),
              title: Text(
                'Search in conversation',
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement search
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                'Clear conversation',
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteConversation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: Text(
                'Block user',
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement block
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear conversation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete all messages? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement delete conversation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversation cleared')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messagingService.getMessagesStream(widget.chatId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final messages = snapshot.data!.docs;

        if (messages.isEmpty) {
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
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation now!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        // Group messages by date
        Map<String, List<DocumentSnapshot>> groupedMessages = {};
        for (var message in messages) {
          final data = message.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'];

          String date = 'No Date';
          if (timestamp != null && timestamp is Timestamp) {
            date = DateFormat('MMMM d, yyyy').format(timestamp.toDate());
          }

          if (!groupedMessages.containsKey(date)) {
            groupedMessages[date] = [];
          }
          groupedMessages[date]!.add(message);
        }

        // Scroll to bottom after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: groupedMessages.length,
          itemBuilder: (context, index) {
            final date = groupedMessages.keys.elementAt(index);
            final dateMessages = groupedMessages[date]!;

            return Column(
              children: [
                _buildDateDivider(date),
                ...dateMessages.map((message) {
                  final data = message.data() as Map<String, dynamic>;
                  final senderId = data['senderId'] as String;
                  final isMe = senderId == _currentUserId;

                  // Check if message should be hidden (deleted for this user)
                  final deletedFor = data['deletedFor'] as List<dynamic>? ?? [];
                  if (deletedFor.contains(_currentUserId)) {
                    return const SizedBox.shrink();
                  }

                  return ChatMessageBubble(
                    messageData: data,
                    isMe: isMe,
                    chatScreenState: this,
                  );
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateDivider(String date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    String displayDate = date;
    try {
      final dateFormat = DateFormat('MMMM d, yyyy');
      final messageDate = dateFormat.parse(date);

      if (messageDate.year == now.year &&
          messageDate.month == now.month &&
          messageDate.day == now.day) {
        displayDate = 'Today';
      } else if (messageDate.year == yesterday.year &&
          messageDate.month == yesterday.month &&
          messageDate.day == yesterday.day) {
        displayDate = 'Yesterday';
      }
    } catch (e) {
      // If date parsing fails, just display the original date string
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                displayDate,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: Colors.grey,
            onPressed: _isRecording ? null : _showAttachmentOptions,
          ),

          // Message input
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isRecording,
                        decoration: InputDecoration(
                          hintText:
                              _isRecording ? 'Recording...' : 'Type a message',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                        ),
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),

                  // Camera button
                  if (!_isRecording && !_isTyping)
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      color: Colors.grey,
                      onPressed: _pickImage,
                    ),
                ],
              ),
            ),
          ),

          // Send button or audio button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: _isTyping
                ? // Send button
                IconButton(
                    key: const ValueKey('sendButton'),
                    icon: const Icon(Icons.send),
                    color: Colors.deepPurple,
                    onPressed: _sendTextMessage,
                  )
                : // Record button
                GestureDetector(
                    key: const ValueKey('micButton'),
                    onLongPress: _startRecording,
                    onLongPressEnd: (_) => _stopRecording(),
                    child: IconButton(
                      icon: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: _isRecording ? Colors.red : Colors.deepPurple,
                      ),
                      onPressed: _isRecording ? () => _stopRecording() : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              height: 5,
              width: 40,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(source: ImageSource.camera);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Gallery',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(source: ImageSource.gallery);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    // Implement document picker
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // ------------- AUDIO RECORDER -------------
  Future<void> _initRecorder() async {
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      if (!mounted) return;
      _showErrorSnackBar('Microphone permission is required for voice notes.');
      return;
    }
    try {
      await _audioRecorder.openRecorder();
      // Update every 200ms
      _audioRecorder.setSubscriptionDuration(const Duration(milliseconds: 200));

      _recorderSub = _audioRecorder.onProgress?.listen((event) {
        if (event != null) {
          setState(() {
            _recordDuration = event.duration;
          });
        }
      });

      setState(() {
        _isRecorderInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error initializing recorder: $e');
    }
  }

  // ------------- AUDIO PLAYER -------------
  Future<void> _initPlayer() async {
    await _player.openPlayer();
    // Let onProgress fire ~5 times a second
    _player.setSubscriptionDuration(const Duration(milliseconds: 200));

    _playerSub = _player.onProgress?.listen((event) {
      if (event != null) {
        setState(() {
          _currentPos = event.position;
          _totalDur = event.duration;
          _isPlaying = _player.isPlaying;
        });
      }
    });

    setState(() {
      _isPlayerInit = true;
    });
  }

  /// Called by the bubble to play/pause a certain audio URL
  Future<void> playOrPauseAudio(String url) async {
    if (!_isPlayerInit) return;

    // If tapping the same URL while playing => pause
    if (_isPlaying && _playingUrl == url) {
      await _player.pausePlayer();
      return;
    }

    // If we are playing a different file, stop it first
    if (_playingUrl != null && _playingUrl != url) {
      await _player.stopPlayer();
    }

    // Start playing the new track
    await _player.startPlayer(
      fromURI: url,
      whenFinished: () {
        setState(() {
          _isPlaying = false;
          _currentPos = Duration.zero;
          _playingUrl = null;
        });
      },
    );

    setState(() {
      _playingUrl = url;
      // isPlaying is set automatically by onProgress
    });
  }

  /// Called by bubble slider to seek within the current track
  Future<void> seekAudio(String url, double milliseconds) async {
    if (_playingUrl == url) {
      final pos = Duration(milliseconds: milliseconds.toInt());
      await _player.seekToPlayer(pos);
    }
  }

  /// Check if a bubble's audio is the currently playing one
  bool isAudioPlaying(String url) => (_playingUrl == url) && _isPlaying;
  Duration currentAudioPosition(String url) =>
      (_playingUrl == url) ? _currentPos : Duration.zero;
  Duration totalAudioDuration(String url) =>
      (_playingUrl == url) ? _totalDur : Duration.zero;

  // ------------- RECORDING HANDLERS -------------
  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      _showErrorSnackBar('Recorder not initialized');
      return;
    }

    try {
      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });

      // Create a temp file
      final tempDir = await Directory.systemTemp.createTemp('audio_recordings');
      final tempFile = '${tempDir.path}/temp_recording.aac';

      await _audioRecorder.startRecorder(
        toFile: tempFile,
        codec: Codec.aacADTS,
      );
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final recordingPath = await _audioRecorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });

      if (recordingPath != null) {
        // Only send if recording is longer than 1 second
        if (_recordDuration.inSeconds > 1) {
          _uploadAndSendAudio(File(recordingPath));
        } else {
          _showErrorSnackBar('Recording too short');
        }
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      _showErrorSnackBar('Error stopping recording: $e');
    }
  }

  // ------------- MESSAGE SENDING -------------
  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    _messageController.clear();

    if (_currentUserId == null) {
      _showErrorSnackBar('User ID not available');
      return;
    }

    try {
      await _messagingService.sendMessage(
        widget.chatId,
        {
          'text': text,
          'senderId': _currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'readBy': [_currentUserId],
        },
      );
    } catch (e) {
      _showErrorSnackBar('Error sending message: $e');
    }
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        _uploadAndSendImage(File(pickedFile.path));
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _uploadAndSendImage(File imageFile) async {
    if (_currentUserId == null) {
      _showErrorSnackBar('User ID not available');
      return;
    }

    setState(() {
      _isSendingMedia = true;
    });

    try {
      // Create a unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.chatId)
          .child(fileName);

      // Upload the file
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;

      // Get download URL
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Send message with image
      await _messagingService.sendMessage(
        widget.chatId,
        {
          'text': '',
          'imageUrl': imageUrl,
          'senderId': _currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'readBy': [_currentUserId],
        },
      );
    } catch (e) {
      _showErrorSnackBar('Error uploading image: $e');
    } finally {
      setState(() {
        _isSendingMedia = false;
      });
    }
  }

  Future<void> _uploadAndSendAudio(File audioFile) async {
    if (_currentUserId == null) {
      _showErrorSnackBar('User ID not available');
      return;
    }

    setState(() {
      _isSendingMedia = true;
    });

    try {
      // Create a unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.aac';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('voice_messages')
          .child(widget.chatId)
          .child(fileName);

      // Upload the file
      final uploadTask = storageRef.putFile(audioFile);
      final snapshot = await uploadTask;

      // Get download URL
      final audioUrl = await snapshot.ref.getDownloadURL();

      // Send message with audio
      await _messagingService.sendMessage(
        widget.chatId,
        {
          'text': '',
          'audioUrl': audioUrl,
          'audioDuration': _recordDuration.inMilliseconds,
          'senderId': _currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'readBy': [_currentUserId],
        },
      );
    } catch (e) {
      _showErrorSnackBar('Error uploading audio: $e');
    } finally {
      setState(() {
        _isSendingMedia = false;
      });
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

  void _showDeleteMenu(String messageId) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(50, 50, 0, 0),
      items: const [
        PopupMenuItem(value: 'me', child: Text('Delete for me')),
        PopupMenuItem(value: 'everyone', child: Text('Delete for everyone')),
      ],
    ).then((value) async {
      try {
        if (value == 'me') {
          await _messagingService.deleteMessageForSenderOnly(
            widget.chatId,
            messageId,
            _currentUserId ?? '',
          );
        } else if (value == 'everyone') {
          await _messagingService.deleteMessageForBoth(
              widget.chatId, messageId);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting message: $e')),
        );
      }
    });
  }
}
