import 'package:flutter/material.dart';

class MyTextfield extends StatefulWidget {
  final String? hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  final VoidCallback? onSubmitted; // ⬅ tambah ini

  const MyTextfield({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.focusNode,
    this.onSubmitted, // ⬅ tambah ini
  });

  @override
  State<MyTextfield> createState() => _MyTextfieldState();
}

class _MyTextfieldState extends State<MyTextfield> {
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          obscureText: _isObscure,
          controller: widget.controller,
          focusNode: widget.focusNode,

          // ⬅ ENTER Key Action
          onSubmitted: (_) {
            if (widget.onSubmitted != null) widget.onSubmitted!();
          },

          style: TextStyle(
            color: colors.onSurface,
            fontSize: 16,
            height: 1.3,
          ),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: colors.onSurface.withOpacity(0.45),
              fontSize: 15,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    splashRadius: 20,
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                      color: colors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
