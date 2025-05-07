import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageBubble extends StatefulWidget {
  final Map<String, dynamic> messageData;
  final bool isMe;
  final dynamic chatScreenState;

  const ChatMessageBubble({
    Key? key,
    required this.messageData,
    required this.isMe,
    required this.chatScreenState,
  }) : super(key: key);

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _showOptionsMenu = false;

  @override
  Widget build(BuildContext context) {
    // Extract message data
    final bool deleted = widget.messageData['deleted'] ?? false;
    final String text = deleted
        ? 'This message was deleted'
        : (widget.messageData['text'] ?? '');
    final String imageUrl = widget.messageData['imageUrl'] ?? '';
    final String audioUrl = widget.messageData['audioUrl'] ?? '';

    // Get timestamp
    String timeString = '';
    if (widget.messageData['timestamp'] != null) {
      if (widget.messageData['timestamp'] is Timestamp) {
        final timestamp = widget.messageData['timestamp'] as Timestamp;
        final dateTime = timestamp.toDate();
        timeString = DateFormat('h:mm a').format(dateTime);
      }
    }

    // Get read status
    final List<dynamic> readBy = widget.messageData['readBy'] ?? [];
    final bool isRead = readBy.length > 1; // If more than sender has read it

    return GestureDetector(
      onLongPress: deleted
          ? null
          : () {
              setState(() {
                _showOptionsMenu = true;
              });
            },
      child: Stack(
        children: [
          // Message bubble
          Align(
            alignment:
                widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(
                top: 4,
                bottom: 4,
                left: widget.isMe ? 64 : 8,
                right: widget.isMe ? 8 : 64,
              ),
              child: Column(
                crossAxisAlignment: widget.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Message content
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: _getBubbleColor(),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: imageUrl.isNotEmpty ? 8 : 16,
                      vertical: imageUrl.isNotEmpty ? 8 : 12,
                    ),
                    child: _buildContent(text, imageUrl, audioUrl, deleted),
                  ),

                  // Timestamp and read status
                  if (timeString.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeString,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (widget.isMe)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                isRead ? Icons.done_all : Icons.done,
                                size: 14,
                                color:
                                    isRead ? Colors.blue : Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Options menu (when long pressed)
          if (_showOptionsMenu)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showOptionsMenu = false;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildOptionItem(
                            icon: Icons.content_copy,
                            label: 'Copy',
                            onTap: text.isNotEmpty
                                ? () {
                                    _copyText(text);
                                    setState(() {
                                      _showOptionsMenu = false;
                                    });
                                  }
                                : null,
                          ),
                          const Divider(height: 1),
                          _buildOptionItem(
                            icon: Icons.reply,
                            label: 'Reply',
                            onTap: () {
                              // Implement reply functionality
                              setState(() {
                                _showOptionsMenu = false;
                              });
                            },
                          ),
                          const Divider(height: 1),
                          _buildOptionItem(
                            icon: Icons.delete_outline,
                            label: widget.isMe
                                ? 'Delete for everyone'
                                : 'Delete for me',
                            onTap: () {
                              _deleteMessage();
                              setState(() {
                                _showOptionsMenu = false;
                              });
                            },
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBubbleColor() {
    if (widget.messageData['deleted'] == true) {
      return widget.isMe ? Colors.grey.shade300 : Colors.grey.shade200;
    }

    return widget.isMe ? Colors.deepPurple.shade100 : Colors.grey.shade100;
  }

  Widget _buildContent(
      String text, String imageUrl, String audioUrl, bool deleted) {
    final List<Widget> contentWidgets = [];

    // Add text if present
    if (text.isNotEmpty) {
      contentWidgets.add(
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: deleted ? Colors.grey.shade600 : Colors.black87,
            fontStyle: deleted ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      );
    }

    // Add image if present
    if (imageUrl.isNotEmpty) {
      if (contentWidgets.isNotEmpty) {
        contentWidgets.add(const SizedBox(height: 8));
      }

      contentWidgets.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () {
              _viewImage(context, imageUrl);
            },
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
                maxHeight: 200,
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    // Add audio if present
    if (audioUrl.isNotEmpty) {
      if (contentWidgets.isNotEmpty) {
        contentWidgets.add(const SizedBox(height: 8));
      }

      contentWidgets.add(
        ModernAudioPlayer(
          audioUrl: audioUrl,
          audioDuration: widget.messageData['audioDuration'] ?? 0,
          isMe: widget.isMe,
          chatScreenState: widget.chatScreenState,
        ),
      );
    }

    // If no content (edge case)
    if (contentWidgets.isEmpty) {
      contentWidgets.add(
        Text(
          'Empty message',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Colors.black87;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyText(String text) {
    // Implement clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
          style: GoogleFonts.poppins(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteMessage() {
    // Implement delete functionality based on isMe
    final messageId = widget.messageData['id'] ?? '';
    if (messageId.isEmpty) {
      // Handle case where messageId is missing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete this message',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Implement proper deletion using the chatScreenState
    if (widget.chatScreenState != null) {
      widget.chatScreenState._showDeleteMenu(messageId);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isMe
              ? 'Message deleted for everyone'
              : 'Message deleted for you',
          style: GoogleFonts.poppins(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModernAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final int audioDuration;
  final bool isMe;
  final dynamic chatScreenState;

  const ModernAudioPlayer({
    Key? key,
    required this.audioUrl,
    required this.audioDuration,
    required this.isMe,
    required this.chatScreenState,
  }) : super(key: key);

  @override
  State<ModernAudioPlayer> createState() => _ModernAudioPlayerState();
}

class _ModernAudioPlayerState extends State<ModernAudioPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _playAnimation;
  bool get isPlaying => widget.chatScreenState.isAudioPlaying(widget.audioUrl);

  Duration get currentPosition =>
      widget.chatScreenState.currentAudioPosition(widget.audioUrl);
  Duration get totalDuration {
    final duration = widget.chatScreenState.totalAudioDuration(widget.audioUrl);
    if (duration.inMilliseconds > 0) {
      return duration;
    }
    // Fallback to the stored duration if available
    return Duration(milliseconds: widget.audioDuration);
  }

  @override
  void initState() {
    super.initState();
    _playAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (isPlaying) {
      _playAnimation.forward();
    }
  }

  @override
  void didUpdateWidget(ModernAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (isPlaying !=
        (oldWidget.chatScreenState.isAudioPlaying(oldWidget.audioUrl))) {
      if (isPlaying) {
        _playAnimation.forward();
      } else {
        _playAnimation.reverse();
      }
    }
  }

  @override
  void dispose() {
    _playAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.deepPurple : Colors.grey.shade700;
    final progressPercent = totalDuration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.deepPurple.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: () {
                  widget.chatScreenState.playOrPauseAudio(widget.audioUrl);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: _playAnimation,
                      color: color,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Waveform and duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fake waveform with progress
                    Container(
                      height: 24,
                      child: Stack(
                        children: [
                          // Background waveform
                          _buildWaveform(color.withOpacity(0.2)),
                          // Progress waveform
                          ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: progressPercent,
                              child: _buildWaveform(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Duration text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(currentPosition),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: color,
                          ),
                        ),
                        Text(
                          _formatDuration(totalDuration),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: color.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform(Color color) {
    // Create a fake waveform with random heights
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        20,
        (index) {
          // Generate a somewhat random pattern, but keep middle bars higher
          final height = (index < 5 || index > 15)
              ? (4 + (index % 3) * 2).toDouble()
              : (10 - (index % 5) * 2).toDouble();

          return Container(
            width: 2,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
