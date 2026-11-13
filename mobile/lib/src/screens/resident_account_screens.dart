import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../ui/app_ui.dart';

class ResidentRegistrationScreen extends StatefulWidget {
  const ResidentRegistrationScreen({super.key});

  @override
  State<ResidentRegistrationScreen> createState() =>
      _ResidentRegistrationScreenState();
}

class _ResidentRegistrationScreenState
    extends State<ResidentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  XFile? _proof;
  bool _hidden = true;
  bool _accepted = false;
  bool _notificationConsent = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _address.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_proof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload a valid ID or proof of residency.'),
        ),
      );
      return;
    }
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that the information is accurate.'),
        ),
      );
      return;
    }
    if (!_notificationConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to receive FloodGuard safety notifications.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await AuthService().registerResident(
        fullName: _name.text,
        email: _email.text,
        mobileNumber: _mobile.text,
        address: _address.text,
        password: _password.text,
        notificationConsent: _notificationConsent,
        proofPath: _proof!.path,
      );
      if (!mounted) return;
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _RegistrationVerificationDialog(
          email: _email.text.trim(),
          initialMessage: result.message,
          emailSent: result.emailSent,
        ),
      );
      if (!mounted || verified != true) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.teal,
            size: 42,
          ),
          title: const Text('Email verified'),
          content: const Text(
            'Your registration is complete and your application is now waiting for administrator approval. You will receive an email when it is approved or rejected.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Return to sign in'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Resident Account')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const AppPageHeader(
              eyebrow: 'Resident registration',
              title: 'Join FloodGuard',
              subtitle: 'Create an account to publish community updates, report incidents, and receive alerts.',
              icon: Icons.person_add_alt_1_outlined,
              color: AppColors.teal,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.length < 2) return 'Enter your complete name.';
                if (!RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿÑñ .'-]+$").hasMatch(name)) {
                  return 'Use letters and standard name punctuation only.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                return _validEmail(value)
                    ? null
                    : 'Enter a valid email address.';
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '09XXXXXXXXX or +639XXXXXXXXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                final mobile = value?.replaceAll(RegExp(r'[\s()-]+'), '') ?? '';
                return RegExp(r'^(?:09\d{9}|\+639\d{9})$').hasMatch(mobile)
                    ? null
                    : 'Use 09XXXXXXXXX or +639XXXXXXXXX.';
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.words,
              minLines: 2,
              maxLines: 3,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Complete address',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _hidden,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText:
                    '10–72 characters with at least one letter and number.',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _hidden ? 'Show passwords' : 'Hide passwords',
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: _passwordValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPassword,
              obscureText: _hidden,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) => value != _password.text
                  ? 'The passwords do not match.'
                  : null,
            ),
            const SizedBox(height: 18),
            const Text(
              'Identity verification',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload a clear photo of a valid ID or document showing that you live in Barangay San Isidro. It will only be visible to authorized administrators.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _pickProof(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take photo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _pickProof(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose photo'),
                  ),
                ),
              ],
            ),
            if (_proof != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAFBF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7E7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.teal),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _proof!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove proof',
                      onPressed: _busy
                          ? null
                          : () => setState(() => _proof = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _accepted,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _accepted = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('I confirm that my information is accurate.'),
              subtitle: const Text(
                'False information may delay barangay assistance.',
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                child: CheckboxListTile(
                  value: _notificationConsent,
                  onChanged: _busy
                      ? null
                      : (value) => setState(
                          () => _notificationConsent = value ?? false,
                        ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.blue,
                  ),
                  title: const Text(
                    'FloodGuard notification consent',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'I agree to receive flood warnings, safety announcements, and updates about my submitted reports. I can manage device notification permission in Android settings.',
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(6, 10, 6, 0),
              child: Text(
                'Live-location sharing is separate and will only start when you enable it for an active response.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: Text(_busy ? 'Creating account...' : 'Create account'),
            ),
          ],
        ),
      ),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    if (password.length < 10 || password.length > 72) {
      return 'Use 10–72 characters.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Include at least one letter and one number.';
    }
    return null;
  }

  Future<void> _pickProof(ImageSource source) async {
    final selected = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (selected != null && mounted) setState(() => _proof = selected);
  }
}

class _RegistrationVerificationDialog extends StatefulWidget {
  const _RegistrationVerificationDialog({
    required this.email,
    required this.initialMessage,
    required this.emailSent,
  });

  final String email;
  final String initialMessage;
  final bool emailSent;

  @override
  State<_RegistrationVerificationDialog> createState() =>
      _RegistrationVerificationDialogState();
}

class _RegistrationVerificationDialogState
    extends State<_RegistrationVerificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  late bool _deliveryReady = widget.emailSent;
  late String _message = widget.initialMessage;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _verifying = true);
    try {
      await AuthService().verifyResidentEmail(
        email: widget.email,
        code: _code.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _message = _errorText(error));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final message = await AuthService().resendResidentVerification(
        widget.email,
      );
      if (mounted) {
        _code.clear();
        setState(() {
          _deliveryReady = true;
          _message = message;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _message = _errorText(error));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: AlertDialog(
      icon: Icon(
        _deliveryReady
            ? Icons.mark_email_unread_outlined
            : Icons.email_outlined,
        color: _deliveryReady ? AppColors.blue : AppColors.danger,
        size: 42,
      ),
      title: const Text('Verify your email'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the six-digit code sent to ${widget.email}.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _deliveryReady ? AppColors.muted : AppColors.danger,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              onFieldSubmitted: (_) {
                if (!_verifying && !_resending) _verify();
              },
              decoration: const InputDecoration(
                labelText: 'Verification code',
                prefixIcon: Icon(Icons.pin_outlined),
                counterText: '',
              ),
              validator: (value) =>
                  value == null || !RegExp(r'^\d{6}$').hasMatch(value.trim())
                  ? 'Enter the six-digit code.'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _verifying || _resending ? null : _resend,
          child: Text(_resending ? 'Sending...' : 'Resend code'),
        ),
        FilledButton(
          onPressed: _verifying || _resending ? null : _verify,
          child: Text(_verifying ? 'Verifying...' : 'Verify'),
        ),
      ],
    ),
  );
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final request = await AuthService().requestPasswordReset(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(request.message)));
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyResetCodeScreen(email: _email.text.trim()),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Forgot Password')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Icon(Icons.lock_reset, size: 62, color: AppColors.blue),
          const SizedBox(height: 18),
          const Text(
            'Reset your password',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your resident account email. We will send a six-digit verification code that expires after 15 minutes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_busy) _request();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => _validEmail(value)
                      ? null
                      : 'Enter a valid email address.',
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _busy ? null : _request,
                  child: Text(
                    _busy ? 'Sending code...' : 'Send verification code',
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

class VerifyResetCodeScreen extends StatefulWidget {
  const VerifyResetCodeScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final result = await AuthService().verifyPasswordResetCode(
        email: widget.email,
        code: _code.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(resetToken: result.resetToken),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verify Code')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const AppPageHeader(
              eyebrow: 'Account security',
              title: 'Check your email',
              subtitle: 'Enter the six-digit verification code we sent.',
              icon: Icons.mark_email_read_outlined,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _code,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_busy) _verify();
              },
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Verification code',
                prefixIcon: Icon(Icons.pin_outlined),
                counterText: '',
              ),
              validator: (value) =>
                  value == null || !RegExp(r'^\d{6}$').hasMatch(value.trim())
                  ? 'Enter the six-digit code from your email.'
                  : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: Text(_busy ? 'Verifying code...' : 'Verify code'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.resetToken});

  final String resetToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidden = true;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final message = await AuthService().resetPassword(
        resetToken: widget.resetToken,
        password: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set New Password')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const AppPageHeader(
              eyebrow: 'Code verified',
              title: 'Create a new password',
              subtitle: 'Your code was accepted. Choose a new password below.',
              icon: Icons.password_outlined,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _password,
              obscureText: _hidden,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final password = value ?? '';
                if (password.length < 10 || password.length > 72) {
                  return 'Use 10–72 characters.';
                }
                if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
                    !RegExp(r'\d').hasMatch(password)) {
                  return 'Include at least one letter and one number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirm,
              obscureText: _hidden,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_busy) _reset();
              },
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) => value != _password.text
                  ? 'The passwords do not match.'
                  : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _reset,
              child: Text(_busy ? 'Changing password...' : 'Change password'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _errorText(Object error) =>
    error.toString().replaceFirst('Exception: ', '');

bool _validEmail(String? value) => RegExp(
  r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
).hasMatch(value?.trim() ?? '');
