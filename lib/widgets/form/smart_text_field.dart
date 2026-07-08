import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Input type for smart keyboard selection
enum SmartInputType {
  text,
  ip,
  port,
  number,
  email,
  macAddress,
  phone,
  password;
}

/// Utility class for MAC address detection and formatting
class MacAddressHelper {
  static final RegExp _macPattern = RegExp(
    r'^([0-9A-Fa-f]{2}[:\-]?){5}[0-9A-Fa-f]{2}$|^[0-9A-Fa-f]{12}$',
  );

  static bool isValidMacFormat(String text) {
    return _macPattern.hasMatch(text);
  }

  static String? detectMacFromClipboard(String clipboardText) {
    final cleaned =
        clipboardText.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
    if (cleaned.length == 12 && RegExp(r'^[0-9A-F]{12}$').hasMatch(cleaned)) {
      return _formatMac(cleaned);
    }
    if (_macPattern.hasMatch(clipboardText)) {
      final noSep =
          clipboardText.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
      return _formatMac(noSep);
    }
    return null;
  }

  static String _formatMac(String mac) {
    final buffer = StringBuffer();
    for (int i = 0; i < mac.length; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(':');
      buffer.write(mac[i]);
    }
    return buffer.toString();
  }

  static String normalizeMac(String mac) {
    final cleaned = mac.replaceAll(RegExp(r'[\s\-:]'), '').toUpperCase();
    return _formatMac(cleaned);
  }
}

/// A smart text field that automatically selects the appropriate keyboard
/// and provides inline validation
class SmartTextField extends StatefulWidget {
  final TextEditingController? controller;
  final SmartInputType inputType;
  final String? labelText;
  final String? hintText;
  final String? prefixText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool autofocus;
  final bool obscureText;
  final int maxLines;
  final bool enabled;
  final bool showInlineError;
  final String? helperText;
  final bool autovalidateMode;
  final bool enableMacPasteDetection;
  final void Function(String formattedMac)? onMacDetected;

  const SmartTextField({
    super.key,
    this.controller,
    this.inputType = SmartInputType.text,
    this.labelText,
    this.hintText,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.nextFocusNode,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.enabled = true,
    this.showInlineError = true,
    this.helperText,
    this.autovalidateMode = false,
    this.enableMacPasteDetection = false,
    this.onMacDetected,
  });

  @override
  State<SmartTextField> createState() => _SmartTextFieldState();
}

class _SmartTextFieldState extends State<SmartTextField> {
  String? _errorText;
  bool _hasBeenEdited = false;

  TextInputType get _keyboardType {
    return switch (widget.inputType) {
      SmartInputType.ip =>
        const TextInputType.numberWithOptions(decimal: true, signed: false),
      SmartInputType.port || SmartInputType.number => TextInputType.number,
      SmartInputType.email => TextInputType.emailAddress,
      SmartInputType.macAddress ||
      SmartInputType.password =>
        TextInputType.text,
      SmartInputType.phone => TextInputType.phone,
      SmartInputType.text => TextInputType.text,
    };
  }

  List<TextInputFormatter>? get _inputFormatters {
    switch (widget.inputType) {
      case SmartInputType.ip:
        return [IPInputFormatter()];
      case SmartInputType.port:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(5),
        ];
      case SmartInputType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      case SmartInputType.macAddress:
        return [MACAddressInputFormatter()];
      default:
        return null;
    }
  }

  TextInputAction get _textInputAction {
    if (widget.nextFocusNode != null) {
      return TextInputAction.next;
    }
    switch (widget.inputType) {
      case SmartInputType.port:
      case SmartInputType.number:
        return TextInputAction.done;
      default:
        return widget.onSubmitted != null
            ? TextInputAction.done
            : TextInputAction.next;
    }
  }

  Future<void> _checkClipboardForMac() async {
    if (!widget.enableMacPasteDetection) return;

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        final detectedMac =
            MacAddressHelper.detectMacFromClipboard(clipboardData!.text!);
        if (detectedMac != null && widget.controller != null) {
          if (!mounted) return;
          final shouldPaste = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('MAC Address Detected'),
              content: Text('Paste MAC address?\n$detectedMac'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Paste'),
                ),
              ],
            ),
          );
          if (shouldPaste == true) {
            widget.controller!.text = detectedMac;
            widget.onMacDetected?.call(detectedMac);
          }
        }
      }
    } catch (_) {}
  }

  void _handleChanged(String value) {
    if (!_hasBeenEdited) {
      setState(() => _hasBeenEdited = true);
    }

    // Run inline validation if enabled
    if (widget.showInlineError && _hasBeenEdited) {
      _validate(value);
    }

    widget.onChanged?.call(value);
  }

  void _validate(String value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != _errorText) {
        setState(() => _errorText = error);
      }
    }
  }

  void _handleSubmitted(String value) {
    _validate(value);

    if (_errorText == null) {
      if (widget.nextFocusNode != null) {
        FocusScope.of(context).requestFocus(widget.nextFocusNode);
      } else {
        widget.onSubmitted?.call(value);
        widget.onEditingComplete?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: _keyboardType,
      textInputAction: _textInputAction,
      inputFormatters: _inputFormatters,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      autocorrect: false,
      enableSuggestions: widget.inputType != SmartInputType.password,
      autovalidateMode: widget.autovalidateMode
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixText: widget.prefixText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20)
            : null,
        suffixIcon: widget.suffixIcon ??
            (widget.enableMacPasteDetection
                ? IconButton(
                    icon: const Icon(Icons.content_paste, size: 20),
                    tooltip: 'Paste MAC address',
                    onPressed: _checkClipboardForMac,
                  )
                : null),
        errorText: widget.showInlineError ? _errorText : null,
        helperText: widget.helperText,
        helperMaxLines: 2,
      ),
      validator: widget.validator,
      onChanged: _handleChanged,
      onFieldSubmitted: _handleSubmitted,
    );
  }
}

/// IP Address input formatter with auto-complete dots
class IPInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow deletion
    if (text.length < oldValue.text.length) {
      return newValue;
    }

    // Only allow digits and dots
    final filtered = text.replaceAll(RegExp(r'[^\d.]'), '');

    // Auto-add dots after 3 digits
    if (text.length > oldValue.text.length && !text.endsWith('.')) {
      final parts = filtered.split('.');
      for (int i = 0; i < parts.length - 1; i++) {
        if (parts[i].length > 3) {
          parts[i] = parts[i].substring(0, 3);
        }
      }

      // Auto-add dot after 3 digits
      if (parts.isNotEmpty &&
          parts.last.length == 3 &&
          parts.length < 4 &&
          !text.endsWith('.')) {
        parts.add('');
        return TextEditingValue(
          text: '${parts.join('.')}.',
          selection: TextSelection.collapsed(
            offset: parts.join('.').length + 1,
          ),
        );
      }
    }

    // Limit to 4 groups
    final parts = filtered.split('.');
    if (parts.length > 4) {
      return oldValue;
    }

    // Limit each part to 3 digits
    for (final part in parts) {
      if (part.length > 3) {
        return oldValue;
      }
    }

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

/// MAC Address input formatter with auto-format
class MACAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();

    // Allow deletion
    if (text.length < oldValue.text.length) {
      return newValue;
    }

    // Remove non-hex characters and colons
    final filtered = text.replaceAll(RegExp(r'[^0-9A-F:]'), '');

    // Remove existing colons for reformatting
    final clean = filtered.replaceAll(':', '');

    // Limit to 12 hex characters
    if (clean.length > 12) {
      return oldValue;
    }

    // Format with colons: AA:BB:CC:DD:EE:FF
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 2 == 0) {
        buffer.write(':');
      }
      buffer.write(clean[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
