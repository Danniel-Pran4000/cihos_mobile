# Rencana Kerja Selanjutnya

Status per 20 Agustus 2026. Diurutkan berdasarkan dampak: yang paling atas
adalah yang membuat aplikasi benar-benar berfungsi, bukan sekadar tampil.

**Sudah selesai:** autentikasi (login/registrasi/sesi), katalog dokter dan
klinik dari API, sistem desain, 90 pengujian otomatis.

---

## P0 — Wajib sebelum aplikasi bisa dipakai

Tanpa bagian ini, aplikasi hanya bisa membaca, tidak bisa melakukan apa pun.

### 1. Membuat janji temu sungguhan

Ini yang paling penting. Tombol "Konfirmasi" di layar Ringkasan **belum
membuat janji apa pun** di sistem rumah sakit.

Endpoint: `POST /api/taptalk/appointment` (`createMedinfras`)

**Masalahnya:** payload yang diminta MEDINFRAS jauh lebih besar daripada yang
dikumpulkan aplikasi sekarang.

Field wajib yang **belum ada** di model `Booking`:

| Field API | Keterangan | Dari mana |
|---|---|---|
| `ServiceUnitCode` | Kode klinik, misal `SU-016` | `Clinic.code` — sudah ada di repository |
| `ParamedicCode` | Kode dokter, misal `D240001` | `Doctor.code` — sudah ada |
| `ParamedicID` | ID dokter (integer) | `Doctor.id` — sudah ada |
| `OperationalTimeCode` | Kode sesi praktik, misal `OT-020` | **Belum diambil** — ada di respons `/schedule`, perlu ditambahkan ke `PracticeSchedule` |
| `Session` | Nomor sesi | `PracticeWindow.session` — sudah ada |
| `StartDate` | Format `yyyyMMdd`, bukan ISO | Perlu formatter baru |
| `slot_no` | Nomor antrean | `BookableSlot.number` — sudah ada |
| `IsNewPatient` | `"0"` atau `"1"` sebagai string | Sudah ada sebagai bool, perlu dikonversi |
| `MedicalNo` | Nomor rekam medis | Dari akun pasien |
| `PatientName` | Nama pasien | Sudah ada |

Langkah:
1. Tambahkan `operational_time_code` ke `PracticeSchedule.fromJson`
2. Perluas `Booking` agar membawa `unitCode`, `paramedicCode`, `operationalTimeCode`, `slotNumber`
3. Buat `BookingRepository.create()` yang menyusun payload MEDINFRAS
4. Sambungkan tombol Konfirmasi, tangani kegagalan (slot keburu diambil orang lain)
5. Tampilkan `BookingCode` asli di layar berhasil, bukan kode karangan

> **Catatan:** ini menulis ke sistem rumah sakit sungguhan. Ujilah dengan data
> uji lebih dulu, dan pastikan ada cara membatalkan janji uji coba.

### 2. Membatalkan janji temu

Endpoint: `POST /api/taptalk/void`

Layar pembatalan sudah ada dan alurnya sudah jalan, tetapi **tidak benar-benar
membatalkan** apa pun. Sheet "sedang diproses" saat ini hanya tampilan.

### 3. Layar Jadwal Booking memakai slot asli

`booking_schedule_screen.dart` masih memakai slot buatan. Repository-nya sudah
siap (`slotsProvider`), tinggal disambungkan:

- Kalender menandai hari praktik dari `doctorSchedulesProvider`
- Hari libur diambil dari `holidaysProvider` (sudah tersedia, belum dipakai)
- Daftar jam dari `slotsProvider`
- Tangani kasus "tidak ada slot tersisa" — sering terjadi dan sekarang belum ditangani

### 4. Jadwal Temu & Riwayat dari data asli

Endpoint: `GET /api/taptalk/find-appointment`

Dua layar ini menampilkan janji temu yang **tidak pernah ada**. Untuk aplikasi
rumah sakit, ini yang paling berisiko membingungkan pasien.

Sudah saya periksa: endpoint ini mencari dengan `medical_no` (wajib) dan
`date` (opsional). Aplikasi sudah menyimpan `medicalNo` dari respons login,
jadi **tidak perlu endpoint baru** — tinggal disambungkan.

Yang perlu diputuskan: bagaimana memisahkan "akan datang" (Jadwal Temu) dari
"sudah selesai" (Riwayat). Kemungkinan cukup dibandingkan dengan tanggal hari
ini di sisi aplikasi.

---

## P1 — Membuat aplikasi layak produksi

### 5. Penanganan sesi kedaluwarsa

Kalau token ditolak saat pasien sedang memakai aplikasi, sekarang yang muncul
hanya pesan error. Seharusnya: keluarkan pasien dan arahkan ke layar masuk.

Tempatnya di `ApiClient` — deteksi 401, lalu picu `signOut()`.

### 6. Status koneksi

Aplikasi ini dipakai di jaringan internal rumah sakit. Kalau pasien berpindah
ke jaringan lain, semua permintaan gagal tanpa penjelasan yang berguna.

Tambahkan banner "Tidak terhubung ke jaringan rumah sakit" yang muncul saat
permintaan gagal karena jaringan.

### 7. Cache dan offline

Sekarang setiap membuka layar selalu memanggil API. Daftar klinik dan dokter
jarang berubah — simpan sementara agar aplikasi tetap berguna saat jaringan
lambat.

### 8. Hasil Pemeriksaan dari data asli

`results_repository.dart` masih dummy. Perlu dicek apakah backend punya
endpoint untuk ini; kemungkinan besar belum, karena data hasil pemeriksaan ada
di sistem rumah sakit yang read-only.

### 9. Info Kesehatan

Backend belum punya endpoint artikel sama sekali. Pilihannya:
- Buat endpoint sederhana di Laravel, atau
- Terima bahwa ini tetap konten statis untuk sementara

Kalau tetap statis, hapus kesan bahwa isinya akan berubah.

### 10. Aset gambar yang hilang

Sembilan berkas masih belum ada: `runner.png`, `promo_1..4`, `jerawat.jpg`,
`eating-clean.jpg`, `teh-tawar.jpg`. Sekarang tampil sebagai *placeholder*.
Perlu diminta ke tim desain atau diganti gambar lain.

---

## P2 — Kualitas dan kerapian

### 11. Hapus data dummy yang sudah tidak dipakai

Setelah semua repository tersambung, hapus:
- `lib/core/data/mock_data.dart`
- Bagian dummy di `doctor_repository.dart`

Selama masih ada, ada risiko layar baru tanpa sengaja memakainya lagi.

### 12. Konsistensi spasi

Masih banyak `padding: 7`, `padding: 6` sisa dari Figma yang belum mengikuti
skala 4pt di `AppSpacing`. Bayangan, radius, dan tipografi sudah dirapikan;
spasi belum.

### 13. Aksesibilitas

- Ukuran sentuh minimal 48x48 — beberapa tombol ikon masih di bawah itu
- Label semantik untuk pembaca layar
- Uji dengan pengaturan teks diperbesar (`textScaleFactor` 1.3+)

Ini penting untuk aplikasi rumah sakit: banyak penggunanya lansia.

### 14. Pengujian tambahan

- Alur booking lengkap sampai janji terbuat (setelah P0 nomor 1)
- Kasus sesi kedaluwarsa
- Kasus slot habis

---

## P3 — Sebelum rilis sungguhan

### 15. Keamanan

- **Ganti `MOBILE_API_KEY`** — kunci yang sekarang sudah pernah dibagikan
- **HTTPS** — server masih HTTP polos. Selama di jaringan internal masih bisa
  diterima, tetapi kalau dipakai dari luar, password bisa disadap
- Pertimbangkan *certificate pinning* setelah HTTPS aktif

### 16. Fitur akun yang belum ada

- Lupa password
- Verifikasi email
- Ubah password
- Hapus akun

Keempatnya perlu endpoint baru di backend.

### 17. Persiapan rilis

- Ikon aplikasi (sekarang masih ikon bawaan Flutter)
- Nama aplikasi di peluncur (`android:label` masih `cihos_mobile`)
- Splash screen native
- ProGuard / R8 untuk rilis
- Uji di layar kecil (360dp) dan besar (tablet)

---

## Catatan

Yang paling menentukan adalah **P0 nomor 1**. Selama membuat janji temu belum
tersambung, aplikasi ini masih berupa katalog baca-saja — pasien bisa melihat
dokter dan jadwal, tetapi tidak bisa memesan apa pun.

Nomor 4 juga penting untuk dikerjakan bersamaan: percuma bisa membuat janji
kalau daftar "Jadwal Temu" tetap menampilkan data karangan.
