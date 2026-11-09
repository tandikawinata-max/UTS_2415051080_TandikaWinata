import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider?>();

    if (session == null) {
      return const SizedBox.shrink();
    }

    return IconButton(
      tooltip: 'Keluar dari akun',
      icon: const Icon(Icons.logout),
      onPressed: session.isBusy
          ? null
          : () async {
              final success = await session.signOut();

              if (!context.mounted || success) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    session.errorMessage ??
                        'Belum berhasil keluar. Silakan coba lagi.',
                  ),
                ),
              );
            },
    );
  }
}
