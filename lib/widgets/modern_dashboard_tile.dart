import 'package:flutter/material.dart';
import 'dart:math' as math;

class ModernDashboardTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? count; // Optional badge count
  final bool isNew; // Indicator for new features

  const ModernDashboardTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.count,
    this.isNew = false,
  });

  @override
  State<ModernDashboardTile> createState() => _ModernDashboardTileState();
}

class _ModernDashboardTileState extends State<ModernDashboardTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.6),
                widget.color.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 22),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Stack(
            children: [
              // Background patterns for visual interest
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  widget.icon,
                  size: isMobile ? 70 : 100,
                  color: widget.color.withOpacity(0.07),
                ),
              ),

              // Main content
              Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 12),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                      ),
                      child: Icon(
                        widget.icon,
                        size: isMobile ? 22 : 28,
                        color: widget.color,
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Badge for counts (notifications, tasks, etc.)
              if (widget.count != null && widget.count! > 0)
                Positioned(
                  top: isMobile ? 8 : 12,
                  right: isMobile ? 8 : 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 4 : 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    ),
                    child: Text(
                      widget.count! > 99 ? "99+" : "${widget.count}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // New feature indicator
              if (widget.isNew)
                Positioned(
                  top: isMobile ? 6 : 8,
                  right: isMobile ? 6 : 8,
                  child: Container(
                    width: isMobile ? 10 : 12,
                    height: isMobile ? 10 : 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white, width: isMobile ? 1.5 : 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
