import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_tracker/providers/providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mosque,
              size: 100,
              color: Colors.teal,
            ),
            const SizedBox(height: 30),
            Text(
              'Salah Tracker',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Track your prayers and improve your consistency.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 60),
            if (authState.isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(authProvider.notifier).signIn();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Login failed: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
