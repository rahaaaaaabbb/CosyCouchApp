1. Front-End (Antarmuka Pengguna)
Framework: Flutter (menggunakan bahasa pemrograman Dart).

Penjelasan & Arsitektur:
Flutter dipilih karena kemampuannya dalam membangun aplikasi multi-platform (dapat berjalan di Android, iOS, maupun Desktop) dari satu basis kode tunggal (single codebase).
Pada sisi antarmuka, aplikasi dirancang agar responsif dan interaktif, menyajikan pengalaman pengguna yang mulus untuk berbagai peran pengguna.

Fitur Utama pada Front-End:
Autentikasi & Hak Akses (Role-Based Access Control): Halaman login terpisah atau dinamis yang membedakan hak akses antara Karyawan/Kasir dan Pemilik (Owner).

Manajemen Produk & Inventaris: Antarmuka untuk melihat daftar barang, menambah produk baru, serta memantau status stok barang masuk dan keluar.

Fitur Pendukung Transaksi: Halaman pencatatan transaksi penjualan, manajemen data konsumen, serta pengelolaan data supplier dan karyawan.

2. Back-End (Logika Server & API)
Framework / Runtime: Node.js dengan pustaka Express.js.

Penjelasan & Arsitektur:
Node.js dan Express.js bertindak sebagai pelayan RESTful API yang menjembatani komunikasi antara aplikasi Flutter (front-end) dengan database.
Arsitektur backend ini berfokus pada kecepatan pemrosesan data, penanganan rute (routing) yang bersih, serta keamanan akses endpoint.

Fitur Utama pada Back-End:

Manajemen API Endpoint: Menyediakan jalur komunikasi untuk operasi CRUD (Create, Read, Update, Delete) data barang, transaksi, karyawan, dan supplier.

Autentikasi & Keamanan: Mengelola proses verifikasi kredensial pengguna (seperti pencocokan hash password) agar akses sistem tetap aman.

Konektivitas Database: Menghubungkan server lokal maupun cloud untuk memastikan sinkronisasi data inventaris berjalan secara real-time.

3. Basis Data (Database)
Teknologi: MySQL (terintegrasi melalui XAMPP untuk lingkungan lokal, serta dukungan migrasi cloud seperti Supabase).
Struktur Utama: Menyimpan tabel relasional penting seperti tabel barang, barang_masuk, barang_keluar, karyawan, konsumen, dan supplier guna memastikan integritas data stok toko tas Anda tetap akurat.
