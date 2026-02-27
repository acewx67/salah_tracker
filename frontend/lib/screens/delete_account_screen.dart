import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_tracker/config/theme.dart';
import 'package:salah_tracker/providers/providers.dart';

/// Screen for permanent account deletion with UUID confirmation.
///
/// Compliant with Google Play Store account deletion requirements:
/// - Clearly explains what data will be deleted
/// - Requires deliberate user action (typing a random UUID) to confirm
/// - Provides option to cancel at any point
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  late String _confirmationCode;
  final _controller = TextEditingController();
  bool _isDeleting = false;
  bool _inputMatches = false;

  @override
  void initState() {
    super.initState();
    _generateCode();
    _controller.addListener(_onInputChanged);
  }

  void _generateCode() {
    // Generate a random 8-character hex string (UUID-like)
    final random = Random.secure();
    _confirmationCode = List.generate(
      8,
      (_) => random.nextInt(16).toRadixString(16),
    ).join().toUpperCase();
  }

  void _onInputChanged() {
    final matches =
        _controller.text.trim().toUpperCase() ==
        _confirmationCode.toUpperCase();
    if (matches != _inputMatches) {
      setState(() => _inputMatches = matches);
    }
  }

  void _regenerateCode() {
    setState(() {
      _generateCode();
      _controller.clear();
      _inputMatches = false;
    });
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      // After deletion, AuthNotifier signs out → authStateChanges fires →
      // AuthWrapper redirects to LoginScreen automatically.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        leading: _isDeleting ? const SizedBox.shrink() : null,
      ),
      body: AbsorbPointer(
        absorbing: _isDeleting,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── Warning Header ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 56,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This action is permanent',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleting your account will permanently remove all your data. '
                    'This cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── What Gets Deleted ────────────────────────────────
            Text(
              'What will be deleted:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _deletionItem(Icons.person_outline, 'Your account and profile'),
            _deletionItem(Icons.book_outlined, 'All prayer logs and history'),
            _deletionItem(Icons.speed_outlined, 'Performance statistics'),
            _deletionItem(
              Icons.settings_outlined,
              'App settings and preferences',
            ),

            const SizedBox(height: 32),

            // ─── Confirmation Code ────────────────────────────────
            Text(
              'Type the code below to confirm:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Code display with copy + regenerate
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _confirmationCode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        fontFamily: 'monospace',
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _confirmationCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Generate new code',
                    onPressed: _regenerateCode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Text input
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 4,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Enter code here',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  letterSpacing: 2,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _inputMatches
                        ? Colors.red.shade400
                        : AppTheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ─── Delete Button ────────────────────────────────────
            AnimatedOpacity(
              opacity: _inputMatches ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton.icon(
                onPressed: _inputMatches && !_isDeleting
                    ? _deleteAccount
                    : null,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_forever),
                label: Text(
                  _isDeleting
                      ? 'Deleting Account...'
                      : 'Permanently Delete Account',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red.shade200,
                  disabledForegroundColor: Colors.white70,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel button
            TextButton(
              onPressed: _isDeleting ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _deletionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
