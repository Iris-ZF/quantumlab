import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/stripe_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);

    return Stack(
      children: [
        _buildContent(context, ref, cs, auth),
        if (auth.isLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ColorScheme cs, AuthState auth) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account section
          _SectionHeader('Account').animate().fadeIn(duration: 300.ms),
          Card(
            child: auth.isSignedIn
                ? ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
                      child: auth.photoUrl == null
                          ? Text((auth.displayName ?? 'U')[0], style: TextStyle(color: cs.onPrimaryContainer))
                          : null,
                    ),
                    title: Text(auth.displayName ?? 'User'),
                    subtitle: Text(auth.email ?? 'Signed in'),
                    trailing: TextButton(
                      onPressed: () => ref.read(authProvider.notifier).signOut(),
                      child: const Text('Sign Out'),
                    ),
                  )
                : Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.login),
                        title: const Text('Sign in with Google'),
                        subtitle: const Text('Sync progress across devices'),
                        onTap: () => ref.read(authProvider.notifier).signInWithGoogle(),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Continue as Guest'),
                        subtitle: const Text('Progress saved locally only'),
                        onTap: () => ref.read(authProvider.notifier).signInAnonymously(),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // Pro upgrade
          _SectionHeader('QuantumLab Pro'),
          Card(
            color: auth.isPro ? Colors.green.withValues(alpha: 0.1) : cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: auth.isPro
                  ? Row(
                      children: [
                        const Icon(Icons.workspace_premium, color: Colors.green),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pro Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('All features unlocked', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.workspace_premium, color: cs.onPrimaryContainer),
                            const SizedBox(width: 10),
                            Text('Upgrade to Pro',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unlock all gates (S, T, SWAP), all 15 lessons, Qiskit/Cirq/QASM export, and unlimited circuit saves.',
                          style: TextStyle(color: cs.onPrimaryContainer.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () => _purchase(context, ref, lifetime: true),
                              child: const Text('\$3.99 Lifetime'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => _purchase(context, ref, lifetime: false),
                              child: const Text('\$1.99/mo'),
                            ),
                          ],
                        ),
                        if (kIsWeb) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Powered by Stripe',
                            style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer.withValues(alpha: 0.5)),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // About
          _SectionHeader('About').animate().fadeIn(delay: 200.ms, duration: 300.ms),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  trailing: Text('1.0.0'),
                ),
                const ListTile(
                  leading: Icon(Icons.code),
                  title: Text('Simulation Engine'),
                  subtitle: Text('PFQVS — novum-qvm v1.2.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('How PFQVS Works'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/pfqvs'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _purchase(BuildContext context, WidgetRef ref, {required bool lifetime}) {
    if (kIsWeb) {
      if (lifetime) {
        StripeService.instance.purchaseLifetime();
      } else {
        StripeService.instance.purchaseMonthly();
      }
    }
    // For demo / testing, show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchase flow initiated. Configure Stripe/IAP for production.')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
