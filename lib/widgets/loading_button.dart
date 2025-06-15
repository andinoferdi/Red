import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class LoadingButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? loadingColor;
  final double fontSize;
  final FontWeight fontWeight;
  final BorderRadius? borderRadius;

  const LoadingButton({
    super.key,
    required this.text,
    required this.isLoading,
    this.onPressed,
    this.width,
    this.height = 56,
    this.backgroundColor,
    this.textColor,
    this.loadingColor,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w600,
    this.borderRadius,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
    
    if (widget.isLoading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(LoadingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _animationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isLoading 
              ? (widget.backgroundColor ?? AppColors.primary).withValues(alpha: 0.8)
              : widget.backgroundColor ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(30),
          ),
          disabledBackgroundColor: (widget.backgroundColor ?? AppColors.primary).withValues(alpha: 0.8),
          elevation: 0,
        ),
        child: widget.isLoading
            ? _buildLoadingIndicator()
            : Text(
                widget.text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                  color: widget.textColor ?? Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: widget.loadingColor ?? Colors.white,
              strokeWidth: 2.5,
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round, // Rounded edges for smoother appearance
              value: 0.8, // Show partial progress for better visual effect
            ),
          ),
        );
      },
    );
  }
}
