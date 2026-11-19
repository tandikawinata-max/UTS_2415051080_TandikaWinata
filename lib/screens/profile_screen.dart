import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_page.dart';

const String studentName = 'Tandika Winata';
const String studentId = '2415051080';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService.instance.logout(); // Menghapus session aktif
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  studentName,
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 4),

                const Text(studentId),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const _ProfileRow(
                    icon: Icons.badge_outlined,
                    label: 'Name',
                    value: 'Tandika Winata',
                  ),

                  const Divider(),

                  const _ProfileRow(
                    icon: Icons.numbers_rounded,
                    label: 'NIM',
                    value: '2415051080',
                  ),

                  const Divider(),

                  const _ProfileRow(
                    icon: Icons.school_outlined,
                    label: 'Class',
                    value: 'PTI 5B',
                  ),

                  const Divider(),

                  _ProfileRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? '-',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon),

          const SizedBox(width: 14),

          Expanded(child: Text(label)),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
