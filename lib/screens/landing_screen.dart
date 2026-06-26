import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'leads_home_screen.dart';
import 'theory_screen.dart';

/// Entry screen: choose between practising Chords or Leads.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Pick',
                style: TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'What do you want to practise?',
                style: TextStyle(
                    fontSize: 15, color: Colors.white.withValues(alpha: 0.6)),
              ),
              Expanded(
                child: Center(
                  child: Row(
                    children: [
                      Expanded(
                        child: _BigOption(
                          icon: Icons.grid_view_rounded,
                          title: 'Chords',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _BigOption(
                          icon: Icons.show_chart_rounded,
                          title: 'Leads',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LeadsHomeScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TheoryScreen()),
                ),
                icon: Icon(Icons.menu_book_outlined, color: scheme.primary, size: 20),
                label: Text('New to scales? Learn the basics',
                    style: TextStyle(color: scheme.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _BigOption({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 46, color: scheme.primary),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
