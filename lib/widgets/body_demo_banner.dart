import 'package:flutter/material.dart';

class BodyDemoBanner extends StatelessWidget {
  const BodyDemoBanner({super.key});
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEMO · Data simulasi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Angka contoh belum dihitung dari foto Anda. Data demo digunakan selama sesi ini dan tidak disimpan sebagai profil atau riwayat akun.',
          ),
        ],
      ),
    ),
  );
}
