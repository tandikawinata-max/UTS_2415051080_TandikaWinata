import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course.dart';
import 'course_data_source.dart';

// Pertemuan 7 & 9 - Integrasi Supabase + RLS
// Tandika Winata - 2415051080

class CourseSupabaseService implements CourseDataSource {
  final SupabaseClient supabase = Supabase.instance.client;

  String get _uid {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User belum login (session tidak ditemukan)');
    }
    return user.id;
  }

  // SELECT: Semua user terautentikasi boleh membaca daftar course
  @override
  Future<List<Course>> getCourses() async {
    final data = await supabase
        .from('courses')
        .select()
        .order('id', ascending: true);

    return data.map((item) => Course.fromJson(item)).toList();
  }

  // INSERT: Wajib menyertakan owner_id sesuai user yang sedang login
  @override
  Future<Course> createCourse(Course course) async {
    final payload = {...course.toJson(), 'owner_id': _uid};
    payload.remove('id'); // Biarkan database yang membuat ID auto-increment

    final row = await supabase
        .from('courses')
        .insert(payload)
        .select()
        .single();

    return Course.fromJson(row);
  }

  // UPDATE: Jika ditolak RLS, Supabase mengembalikan 0 baris (rows kosong)
  @override
  Future<void> updateCourse(int id, Course course) async {
    final payload = Map<String, dynamic>.from(course.toJson());
    payload.remove('id');
    payload.remove('owner_id'); // Jangan ubah kepemilikan data saat update

    final rows = await supabase
        .from('courses')
        .update(payload)
        .eq('id', id)
        .select();

    if (rows.isEmpty) {
      throw Exception(
        'ACCESS DENIED: Anda tidak memiliki izin untuk mengubah course ini.',
      );
    }
  }

  // DELETE: Jika ditolak RLS, Supabase mengembalikan 0 baris (rows kosong)
  @override
  Future<void> deleteCourse(int id) async {
    final rows = await supabase.from('courses').delete().eq('id', id).select();

    if (rows.isEmpty) {
      throw Exception(
        'ACCESS DENIED: Anda tidak memiliki izin untuk menghapus course ini.',
      );
    }
  }
}
