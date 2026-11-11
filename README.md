# Usize

**Your Size, Your Confidence.**

Usize merupakan aplikasi Flutter Android yang dikembangkan untuk membantu pengguna memilih ukuran pakaian berdasarkan ukuran tubuh pribadi dan tabel ukuran produk.

Alur utama: profil tubuh → screenshot → tabel terisi otomatis → koreksi bila diperlukan → analisis → simpan hasil. Input tabel manual tersedia sebagai cadangan.

Proyek ini dibuat untuk UTS Pemrograman Mobile. Versi awal berfokus pada pakaian atasan dengan ukuran tubuh yang dimasukkan secara manual.

## Identitas Pengembang

| Informasi           | Keterangan                     |
| ------------------- | ------------------------------ |
| Nama                | Tandika Winata                 |
| NIM                 | 2415051080                     |
| Kelas               | Belum diisi                    |
| Universitas         | Universitas Pendidikan Ganesha |
| Mata kuliah         | Pemrograman Mobile             |
| Nama aplikasi       | Usize                          |
| Nama paket Dart     | `usize`                        |
| Platform            | Android                        |
| Branch pengembangan | `usize`                        |

Pengembangan Usize menggunakan branch `usize` pada repositori yang juga menyimpan tugas worksheet. Pekerjaan worksheet berada pada branch `main`.

[Buka branch Usize](https://github.com/tandikawinata-max/flutter_ui_fundamentals/tree/usize)

## Fitur dan Progres

| Fitur                               | Status                              |
| ----------------------------------- | ----------------------------------- |
| Struktur folder aplikasi            | Disiapkan pada Tahap 02             |
| Model ukuran tubuh dan tabel ukuran | Disiapkan pada Tahap 02             |
| Kontrak repository profil           | Disiapkan pada Tahap 02             |
| Pemilihan screenshot dari galeri    | Berhasil diuji                      |
| Preview gambar                      | Berhasil diuji                      |
| OCR gambar berisi teks sederhana    | Berhasil diuji                      |
| Pesan ketika teks tidak ditemukan   | Berhasil ditampilkan                |
| Dashboard                           | Terintegrasi dengan profil dan riwayat |
| Tiga reusable widgets               | Disiapkan pada Tahap 04             |
| Layout compact dan wide             | Diuji otomatis termasuk teks 200% |
| Navigasi utama dan detail profil    | Diimplementasikan pada Tahap 05    |
| Shared state dengan Provider        | Diimplementasikan pada Tahap 06    |
| Panduan pengukuran dari REST API    | Diimplementasikan pada Tahap 07    |
| Database dan CRUD profil            | Diimplementasikan pada Tahap 08–11 |
| Penyempurnaan impor screenshot      | Diimplementasikan pada Tahap 12    |
| Koreksi dan verifikasi tabel OCR    | Tahap 13, direvisi bersama Tahap 14 |
| Analisis kecocokan ukuran           | Tahap 14, mendukung angka dan rentang |
| Penyimpanan riwayat analisis        | Diimplementasikan pada Tahap 15    |

Mode aplikasi memakai akun Supabase. Repository demo hanya digunakan bila disuntikkan secara eksplisit, terutama dalam pengujian. Bukti pemeriksaan terbaru dan status APK tersedia pada dokumentasi Tahap 16.

## Tech Stack

| Teknologi                       | Penggunaan                                    |
| ------------------------------- | --------------------------------------------- |
| Flutter                         | Pengembangan aplikasi Android                 |
| Dart                            | Bahasa pemrograman                            |
| Material 3                      | Tema dan komponen antarmuka                   |
| `image_picker`                  | Pemilihan gambar dari galeri                  |
| `google_mlkit_text_recognition` | Pembacaan teks menggunakan ML Kit             |
| `flutter_test`                  | Pengujian widget                              |
| Git dan GitHub                  | Pengelolaan versi serta progres pengembangan  |
| Provider + ChangeNotifier       | Pengelolaan shared state                     |
| HTTP REST client                | Pengambilan panduan pengukuran               |
| Supabase PostgreSQL             | Penyimpanan profil dan hasil analisis        |

Versi dependency tercatat dalam `pubspec.yaml` dan `pubspec.lock`.

## Struktur Proyek

| Lokasi              | Tanggung jawab                                   |
| ------------------- | ------------------------------------------------ |
| `lib/main.dart`     | Titik awal aplikasi, tema, dan halaman pembuka   |
| `lib/models/`       | Representasi data aplikasi                       |
| `lib/services/`     | Akses OCR, REST API, dan database                |
| `lib/repositories/` | Kontrak dan pengelolaan akses data               |
| `lib/providers/`    | Pengelolaan state aplikasi                       |
| `lib/config/`       | Validasi konfigurasi publik                     |
| `lib/screens/`      | Halaman aplikasi                                 |
| `lib/widgets/`      | Komponen tampilan yang digunakan ulang           |
| `test/`             | Pengujian aplikasi                               |
| `tool/`             | Pemeriksaan dan build APK                        |

### Model Data

| Model              | Kegunaan                                        |
| ------------------ | ----------------------------------------------- |
| `BodyMeasurement`  | Menyimpan identitas profil dan ukuran tubuh     |
| `SizeChart`        | Merepresentasikan satu tabel ukuran             |
| `SizeChartRow`     | Merepresentasikan satu baris ukuran             |
| `MeasurementRange` | Menyimpan batas bawah dan batas atas pengukuran |

Jenis ukuran dan satuan disimpan secara eksplisit agar lingkar tubuh, lingkar pakaian, serta lebar pakaian dapat dibedakan saat analisis.

### Reusable Widgets

| Widget            | Kegunaan                                         |
| ----------------- | ------------------------------------------------ |
| `SectionHeader`   | Menampilkan judul dan deskripsi bagian           |
| `MeasurementCard` | Menampilkan profil ukuran tubuh                  |
| `EmptyState`      | Menampilkan informasi ketika data belum tersedia |

## Arsitektur Aplikasi

Alur akses data adalah UI → Provider → Repository → Service/Data Source → REST API atau Database.

Provider mengelola data, loading, error, dan profil aktif. Repository menyediakan operasi pengelolaan data, sedangkan service menangani komunikasi dengan sumber data.

State screenshot dikelola ScreenshotProvider. OcrService menyediakan teks dan koordinat untuk parser tabel; hasil dapat dikoreksi sebelum analisis.

## Tampilan Responsif

Dashboard menggunakan `LayoutBuilder` untuk menyesuaikan susunan kartu berdasarkan lebar ruang aplikasi.

| Kondisi                              | Tampilan                                           |
| ------------------------------------ | -------------------------------------------------- |
| Lebar kurang dari 600 logical pixels | Satu kolom kartu profil                            |
| Lebar mulai 600 logical pixels       | Dua kolom kartu profil                             |
| Layar sangat lebar                   | Lebar konten dibatasi maksimal 1100 logical pixels |

`ListView` menyediakan scrolling halaman. `Wrap` mengatur susunan kartu dengan tinggi yang mengikuti isi.

## REST API

Panduan pengukuran diambil melalui GET `/rest/v1/measurement_guides` pada proyek Supabase yang dikonfigurasi.

Integrasi pada Tahap 07 mencakup operasi GET, konversi JSON menjadi model Dart, dan penampilan data pada halaman panduan.

Halaman tersebut memiliki loading, empty, dan error state serta tombol coba lagi.

## Backend dan Database

Backend menggunakan Supabase PostgreSQL.

Tabel utama `body_measurements` mencakup kolom berikut; definisi lengkap tersedia pada folder supabase.

| Kolom         | Kegunaan               |
| ------------- | ---------------------- |
| `id`          | Primary key profil     |
| `user_id`     | Identitas pemilik data |
| `label`       | Nama profil            |
| `chest_cm`    | Lingkar dada           |
| `waist_cm`    | Lingkar pinggang       |
| `hip_cm`      | Lingkar pinggul        |
| `measured_at` | Waktu pengukuran       |

CRUD profil dikembangkan pada Tahap 08–11. Penyimpanan hasil analisis menggunakan tabel `fit_analyses` pada Tahap 15.

Autentikasi dan Row Level Security membatasi akses data berdasarkan pengguna setelah SQL diterapkan.

Password, token server, `service_role` key, dan keystore disimpan di luar repositori.

## Cara Menjalankan

Siapkan Flutter SDK, Git, Android SDK, serta emulator atau HP Android.

Konfigurasi Android pada Tahap 03 menggunakan pengaturan berikut.

| Pengaturan      | Nilai               |
| --------------- | ------------------- |
| `minSdk`        | 24                  |
| `compileSdk`    | 36                  |
| `targetSdk`     | 36                  |
| Target Java     | 17                  |
| `applicationId` | `com.example.usize` |

Untuk mendapatkan salinan proyek setelah branch `usize` tersedia di GitHub, jalankan perintah berikut.

```powershell
git clone --branch usize https://github.com/tandikawinata-max/flutter_ui_fundamentals.git UTS_2415051080_TandikaWinata
cd UTS_2415051080_TandikaWinata
flutter doctor -v
flutter pub get
flutter devices
flutter run --dart-define-from-file=config/local.json
```

Siapkan config/local.json dengan URL HTTPS dan publishable key proyek Supabase. Terapkan SQL profil dan riwayat pada proyek yang sama. Pilih perangkat Android ketika diminta.

Untuk proyek yang sudah tersedia di laptop, buka folder yang berisi `pubspec.yaml`, lalu jalankan mulai dari `flutter pub get`.

## Cara Menguji OCR

1. Siapkan gambar PNG atau JPG dengan tulisan yang jelas.
2. Masukkan gambar ke HP atau emulator Android.
3. Buka aplikasi Usize.
4. Pada dashboard, tekan **Buka pembaca tabel**.
5. Tekan **Pilih screenshot**.
6. Pilih gambar dan tunggu pemrosesan selesai.
7. Bandingkan hasil OCR dengan tulisan serta angka pada gambar asli.

Pada versi Tahap 03, aplikasi langsung membuka halaman uji OCR.

File yang diseret dari laptop ke emulator biasanya tersedia di folder Downloads. Gunakan menu jelajah file jika gambar belum muncul pada tab foto.

Parsing tabel, koreksi rentang dan pemulihan screenshot sudah diimplementasikan. Perilaku native Android dan akurasi pada gambar nyata tetap diperiksa melalui checklist Tahap 16.

## Pengujian

Jalankan pemeriksaan berikut dari folder utama proyek.

```powershell
dart format lib test tool
flutter analyze
flutter test
```

Catatan berikut merupakan hasil pengembangan awal Tahap 03–04, bukan status terbaru. Hasil terbaru ada di [docs/testing/tahap16.md](docs/testing/tahap16.md).

| Skenario                               | Hasil yang telah dicatat              |
| -------------------------------------- | ------------------------------------- |
| Memilih gambar dan menampilkan preview | Berhasil                              |
| Membaca gambar berisi teks sederhana   | Berhasil                              |
| Membaca gambar tabel ukuran pertama    | Teks kosong, perlu pengujian lanjutan |
| Membatalkan pemilihan gambar           | Belum dicatat                         |
| Analisis kode setelah Tahap 04         | Belum dicatat                         |
| Widget test setelah Tahap 04           | Belum dicatat                         |
| Layout compact dan wide                | Belum dicatat                         |
| Dashboard menuju OCR dan kembali       | Belum dicatat                         |

Pengujian widget memeriksa tampilan dan interaksi Flutter. Pembacaan OCR diuji langsung pada perangkat Android.

## Screenshot Aplikasi

Screenshot akan ditambahkan setelah hasil pengujian tersedia. Simpan gambar dokumentasi di folder `docs/screenshots/`.

| Nama file                        | Isi                              |
| -------------------------------- | -------------------------------- |
| `tahap03_ocr_teks_berhasil.png`  | Gambar uji dan teks hasil OCR    |
| `tahap03_ocr_tabel_berhasil.png` | Tabel ukuran dan hasil pembacaan |
| `tahap04_dashboard.png`          | Bagian atas dashboard            |
| `tahap04_profil_compact.png`     | Profil dalam satu kolom          |
| `tahap04_profil_wide.png`        | Profil dalam dua kolom           |

Setelah gambar tersedia, gunakan format berikut untuk menampilkannya.

```markdown
Tambahkan screenshot perangkat setelah pengujian nyata; hasil widget test tidak digunakan sebagai bukti galeri/OCR native.
```

Dokumentasi akhir UTS akan dilengkapi dengan screenshot Home, List, Detail, Create, Edit, layout compact dan wide, data REST API, serta data database.

## Tahapan Pengembangan

| Tahap | Pekerjaan                                         |
| ----- | ------------------------------------------------- |
| 01    | Inisialisasi proyek Flutter dan Git               |
| 02    | Arsitektur, model, dan kontrak repository         |
| 03    | Validasi pemilihan gambar dan OCR                 |
| 04    | Dashboard, reusable widgets, dan layout responsif |
| 05    | Navigasi utama dan passing data                   |
| 06    | Provider dan shared state                         |
| 07    | Integrasi REST GET panduan pengukuran             |
| 08    | Supabase, kontrol akses, dan operasi Read         |
| 09    | Tambah profil dengan validasi                     |
| 10    | Edit profil                                       |
| 11    | Hapus profil dengan konfirmasi                    |
| 12    | Penyempurnaan alur impor screenshot               |
| 13    | Parsing, koreksi, dan verifikasi tabel            |
| 14    | Analisis kecocokan ukuran                         |
| 15    | Penyimpanan dan pengelolaan riwayat               |
| 16    | Pengujian menyeluruh dan verifikasi APK           |
| 17    | Dokumentasi, pengumpulan, dan demo                |

Setiap tahap diperiksa, di-commit, dan di-push secara bertahap. Target pengembangan adalah 17 commit utama Usize.

Periksa riwayat commit Usize dengan perintah berikut.


## Tahap 14 — Tabel otomatis dan analisis ukuran (termasuk revisi Tahap 13)

Alur terbaru: screenshot → tabel terisi otomatis → koreksi bila diperlukan → analisis.
Bagian ini menggantikan ketentuan pemeriksaan manual/checkbox Tahap 13 di atas.

OCR kini mempertahankan koordinat elemen. Parser menyusun tabel menurut posisi,
mempertahankan sel kosong, dan mengenali satuan/jenis pengukuran dari keterangan yang jelas.
Pratinjau menampilkan angka sumber; tombol koreksi menjadi pilihan. Input manual menjadi cadangan.

Angka tunggal dan rentang seperti `92 - 97`, `92–97`, atau `92,5–97,5` diterima.
Kedua batas disimpan; angka tidak diganti dengan rata-rata. Jenis tabel disimpulkan dari
keterangan sumber yang eksplisit, atau dipilih sekali tanpa mengetik ulang angka.

Tabel ukuran tubuh dicocokkan langsung dengan rentang, tanpa tambahan kelonggaran.
Untuk ukuran pakaian jadi, analisis memakai target Rapat (2–4 cm), Reguler (4–10 cm),
atau Longgar (10–18 cm). Rentang variasi pakaian dinilai pada kedua batasnya;
rentang regangan atau rentang yang maknanya belum diketahui memerlukan informasi tambahan.
Hasil berisi kandidat, alasan, dan kondisi data belum lengkap/sebagian cocok/tidak ada kandidat.
Ini aturan awal Usize, bukan standar semua merek.

Panduan, batasan parser, fixture, dan checklist Android: [docs/testing/tahap14.md](docs/testing/tahap14.md).
Hasil masih sementara; riwayat permanen belum ditambahkan. Seluruh revisi ini satu commit Tahap 14.


## Tahap 15 — Riwayat analisis dan penyempurnaan tampilan

Alur lengkap: screenshot → tabel otomatis → koreksi bila diperlukan → analisis → Simpan hasil → riwayat/detail.
Hasil disimpan ke Supabase `fit_analyses` milik akun yang sedang masuk. Snapshot mencakup profil tubuh,
angka sumber, satuan/jenis tabel, kedua batas rentang, perbandingan, rekomendasi, catatan, dan versi aturan.
Riwayat tidak dihitung ulang atau ikut dihapus ketika profil tubuh berubah/dihapus.

Daftar mendukung muat ulang dan halaman berikutnya; detail dibuka berdasarkan ID. Hapus membutuhkan
konfirmasi. Percobaan simpan ulang memakai ID hasil yang sama agar respons jaringan yang hilang tidak
membuat duplikasi. Akses baca/simpan/hapus dilindungi RLS; UPDATE tidak diberikan untuk hasil historis.

Tema global menggunakan palet #b7ccc8, #27818a, #99c0d1, #d0d0d2 dengan bottom navigation.
Berkas screenshot asli belum diunggah; yang disimpan adalah data tabel dan hasil analisis.

Jalankan `supabase/fit_analyses.sql` pada proyek Supabase sebelum mencoba penyimpanan akun.
Panduan pemasangan: [docs/testing/penerapan_tahap15.md](docs/testing/penerapan_tahap15.md).
Rincian pengujian dan batasan: [docs/testing/tahap15.md](docs/testing/tahap15.md).


## Tahap 16 — Pengujian menyeluruh dan persiapan verifikasi APK

- Layar pembukaan aplikasi dengan loading, penjelasan konfigurasi tidak valid, dan retry.
- Header tabel menyesuaikan pembesaran teks agar judul dua baris tidak terpotong.
- Tambahan pengujian lebar 320/390/1024, teks 200%, keyboard, simpan riwayat, dan Back.
- Perintah pemeriksaan: `dart run tool/verify_release.dart`; gunakan `--checks-only` jika tanpa APK.
- Hasil pemeriksaan kode: 141 tes lolos, analyzer tanpa issue, format sesuai.
- APK dan fitur Android/Supabase nyata belum terverifikasi; tidak ada APK yang disertakan.

Panduan pemasangan: [docs/testing/penerapan_tahap16.md](docs/testing/penerapan_tahap16.md).
Hasil, keterbatasan, dan checklist perangkat: [docs/testing/tahap16.md](docs/testing/tahap16.md).
