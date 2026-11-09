# Usize

**Your Size, Your Confidence.**

Usize merupakan aplikasi Flutter Android yang dikembangkan untuk membantu pengguna memilih ukuran pakaian berdasarkan ukuran tubuh pribadi dan tabel ukuran produk.

Alur yang direncanakan meliputi input ukuran tubuh, impor screenshot tabel ukuran, pembacaan teks menggunakan OCR, verifikasi tabel, serta analisis kecocokan ukuran.

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

## Status Pengembangan

Proyek sedang memasuki Tahap 04, yaitu pembuatan dashboard, reusable widgets, dan layout responsif.

Pemilihan gambar dan pembacaan gambar berisi teks sederhana sudah berhasil diuji pada emulator Android. Pengujian awal menggunakan gambar tabel ukuran menghasilkan teks kosong sehingga diperlukan pengujian lanjutan dengan gambar yang lebih jelas.

Kode dashboard dan pengujian responsif sudah disiapkan. Hasil pemeriksaan pada proyek lokal akan dicatat setelah pengujian selesai.

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
| Dashboard                           | Dalam pengerjaan Tahap 04           |
| Tiga reusable widgets               | Disiapkan pada Tahap 04             |
| Layout compact dan wide             | Menunggu konfirmasi hasil pengujian |
| Navigasi utama dan detail profil    | Direncanakan pada Tahap 05          |
| Shared state dengan Provider        | Direncanakan pada Tahap 06          |
| Panduan pengukuran dari REST API    | Direncanakan pada Tahap 07          |
| Database dan CRUD profil            | Direncanakan pada Tahap 08–11       |
| Penyempurnaan impor screenshot      | Direncanakan pada Tahap 12          |
| Koreksi dan verifikasi tabel OCR    | Direncanakan pada Tahap 13          |
| Analisis kecocokan ukuran           | Direncanakan pada Tahap 14          |
| Penyimpanan riwayat analisis        | Direncanakan pada Tahap 15          |

Profil pada dashboard Tahap 04 menggunakan data contoh untuk menguji tampilan.

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
| Provider + ChangeNotifier       | Rencana pengelolaan shared state              |
| HTTP REST client                | Rencana pengambilan panduan pengukuran        |
| Supabase PostgreSQL             | Rencana penyimpanan profil dan hasil analisis |

Versi dependency tercatat dalam `pubspec.yaml` dan `pubspec.lock`.

## Struktur Proyek

| Lokasi              | Tanggung jawab                                   |
| ------------------- | ------------------------------------------------ |
| `lib/main.dart`     | Titik awal aplikasi, tema, dan halaman pembuka   |
| `lib/models/`       | Representasi data aplikasi                       |
| `lib/services/`     | Akses OCR, REST API, dan database                |
| `lib/repositories/` | Kontrak dan pengelolaan akses data               |
| `lib/providers/`    | Pengelolaan state aplikasi pada tahap berikutnya |
| `lib/screens/`      | Halaman aplikasi                                 |
| `lib/widgets/`      | Komponen tampilan yang digunakan ulang           |
| `test/`             | Pengujian aplikasi                               |

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

Alur akses data yang dituju adalah UI → Provider → Repository → Service/Data Source → REST API atau Database.

Provider akan mengelola data, loading, error, dan profil aktif. Repository menyediakan operasi pengelolaan data, sedangkan service menangani komunikasi dengan sumber data.

Pada prototipe OCR, state lokal halaman menggunakan `setState`. Pemrosesan teks dipisahkan ke `OcrService`.

## Tampilan Responsif

Dashboard menggunakan `LayoutBuilder` untuk menyesuaikan susunan kartu berdasarkan lebar ruang aplikasi.

| Kondisi                              | Tampilan                                           |
| ------------------------------------ | -------------------------------------------------- |
| Lebar kurang dari 600 logical pixels | Satu kolom kartu profil                            |
| Lebar mulai 600 logical pixels       | Dua kolom kartu profil                             |
| Layar sangat lebar                   | Lebar konten dibatasi maksimal 1100 logical pixels |

`ListView` menyediakan scrolling halaman. `Wrap` mengatur susunan kartu dengan tinggi yang mengikuti isi.

## REST API

REST API yang direncanakan adalah Measurement Guide API untuk menyediakan panduan pengukuran tubuh.

Integrasi pada Tahap 07 mencakup operasi GET, konversi JSON menjadi model Dart, dan penampilan data pada halaman panduan.

Halaman tersebut akan memiliki loading, empty, dan error state serta tombol coba lagi.

Endpoint aktif akan dicantumkan setelah implementasi selesai.

## Backend dan Database

Backend yang direncanakan adalah Supabase PostgreSQL.

Tabel utama `body_measurements` direncanakan memiliki kolom berikut.

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

Autentikasi dan Row Level Security akan digunakan untuk membatasi akses data berdasarkan pengguna.

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
flutter run
```

Pilih perangkat Android ketika diminta.

Untuk proyek yang sudah tersedia di laptop, buka folder yang berisi `pubspec.yaml`, lalu jalankan mulai dari `flutter pub get`.

## Cara Menguji OCR

1. Siapkan gambar PNG atau JPG dengan tulisan yang jelas.
2. Masukkan gambar ke HP atau emulator Android.
3. Buka aplikasi Usize.
4. Pada dashboard Tahap 04, tekan **Buka pembaca tabel**.
5. Tekan **Pilih screenshot**.
6. Pilih gambar dan tunggu pemrosesan selesai.
7. Bandingkan hasil OCR dengan tulisan serta angka pada gambar asli.

Pada versi Tahap 03, aplikasi langsung membuka halaman uji OCR.

File yang diseret dari laptop ke emulator biasanya tersedia di folder Downloads. Gunakan menu jelajah file jika gambar belum muncul pada tab foto.

Parsing tabel dan verifikasi pengguna akan dikembangkan pada Tahap 13. Pemulihan gambar ketika Android menghentikan aplikasi saat pemilih gambar terbuka direncanakan pada Tahap 12.

## Pengujian

Jalankan pemeriksaan berikut dari folder utama proyek.

```powershell
dart format lib test
flutter analyze
flutter test
```

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
![Dashboard Usize](docs/screenshots/tahap04_dashboard.png)
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
