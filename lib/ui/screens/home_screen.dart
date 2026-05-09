import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lesson_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final progress = ref.watch(lessonProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _Header(auth: auth, cs: cs, ref: ref)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.3 : 1.1,
                ),
                delegate: SliverChildListDelegate([
                  _NavCard(
                    icon: Icons.construction,
                    title: 'Circuit\nBuilder',
                    color: cs.primary,
                    onTap: () => context.go('/builder'),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: 100.ms, duration: 300.ms, curve: Curves.easeOut),
                  _NavCard(
                    icon: Icons.school,
                    title: 'Learn\nQuantum',
                    color: cs.tertiary,
                    badge: '${progress.completedLessons.length}/15',
                    onTap: () => context.go('/lessons'),
                  ).animate().fadeIn(delay: 150.ms, duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: 150.ms, duration: 300.ms, curve: Curves.easeOut),
                  _NavCard(
                    icon: Icons.code,
                    title: 'QASM\nEditor',
                    color: const Color(0xFF00897B),
                    onTap: () => context.go('/qasm'),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: 200.ms, duration: 300.ms, curve: Curves.easeOut),
                  _NavCard(
                    icon: Icons.blur_on,
                    title: 'PFQVS\nEngine',
                    color: const Color(0xFFE65100),
                    onTap: () => context.go('/pfqvs'),
                  ).animate().fadeIn(delay: 250.ms, duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: 250.ms, duration: 300.ms, curve: Curves.easeOut),
                  _NavCard(
                    icon: Icons.settings,
                    title: 'Settings\n& Pro',
                    color: cs.secondary,
                    onTap: () => context.go('/settings'),
                  ).animate().fadeIn(delay: 300.ms, duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: 300.ms, duration: 300.ms, curve: Curves.easeOut),
                  if (auth.isPro)
                    _NavCard(
                      icon: Icons.workspace_premium,
                      title: 'Pro\nActive',
                      color: Colors.amber.shade700,
                      onTap: () => context.go('/settings'),
                    ).animate().fadeIn(delay: 350.ms, duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: 350.ms, duration: 300.ms, curve: Curves.easeOut),
                ]),
              ),
            ),
            // Quick stats
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverToBoxAdapter(
                child: _StatsRow(progress: progress, cs: cs)
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 400.ms, duration: 400.ms, curve: Curves.easeOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AuthState auth;
  final ColorScheme cs;
  final WidgetRef ref;

  const _Header({required this.auth, required this.cs, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.blur_on, color: cs.onPrimary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QuantumLab',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                auth.isSignedIn ? 'Welcome, ${auth.displayName ?? "User"}' : 'Quantum Circuit Builder',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
        if (!auth.isSignedIn)
          auth.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : OutlinedButton.icon(
                  onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('Sign in'),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                )
        else
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
            child: auth.photoUrl == null
                ? Text(
                    (auth.displayName ?? 'U')[0].toUpperCase(),
                    style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge!, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ),
                ],
              ),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final LessonProgress progress;
  final ColorScheme cs;

  const _StatsRow({required this.progress, required this.cs});

  @override
  Widget build(BuildContext context) {
    final quantumDone = progress.completedLessons.entries
        .where((e) => e.key.startsWith('q') && !e.key.startsWith('qasm') && e.value)
        .length;
    final qasmDone = progress.completedLessons.entries
        .where((e) => e.key.startsWith('qasm') && e.value)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _Stat(label: 'Quantum', value: '$quantumDone/10', cs: cs)),
            Container(width: 1, height: 32, color: cs.outlineVariant),
            Expanded(child: _Stat(label: 'QASM', value: '$qasmDone/5', cs: cs)),
            Container(width: 1, height: 32, color: cs.outlineVariant),
            Expanded(
              child: _Stat(
                label: 'Status',
                value: progress.allQuantumComplete ? 'Advanced' : 'Learning',
                cs: cs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _Stat({required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.primary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}
