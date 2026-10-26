const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const ExcelJS = require('exceljs');
const crypto = require('crypto');
const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage: storage });

const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'db_cosycouch'
});

db.connect((err) => {
  if (err) return console.error('Koneksi gagal:', err);
  console.log('Terhubung ke MySQL Localhost');
});

// 1. ENDPOINT LOGIN (Dengan Hash SHA-256)
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  
  // Mengubah password yang diketik menjadi kode Hash
  const hashedPassword = crypto.createHash('sha256').update(password).digest('hex');
  
  // Mencari ke tabel karyawan menggunakan password yang sudah di-hash
  db.query('SELECT id_karyawan AS id_user, username, nama_karyawan AS nama_lengkap, jabatan AS role FROM karyawan WHERE username = ? AND password = ?', [username, hashedPassword], (err, results) => {
    
    if (err) {
      console.error('ERROR DATABASE:', err.message);
      return res.status(500).json({ error: err.message });
    }

    if (results.length > 0) {
      res.json({ message: 'Login berhasil', user: results[0] });
    } else {
      res.status(401).json({ error: 'Username atau password salah' });
    }
  });
});

// 2. ENDPOINT BARANG
app.get('/api/barang', (req, res) => {
  db.query('SELECT * FROM barang ORDER BY kode_barang DESC', (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

app.post('/api/barang-foto', upload.single('foto'), (req, res) => {
  const data = { ...req.body, foto: req.file ? req.file.filename : null };
  db.query('INSERT INTO barang SET ?', data, (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Barang ditambahkan' });
  });
});

// 3. ENDPOINT TRANSAKSI MASUK
app.post('/api/barang-masuk', (req, res) => {
  const { kode_barang, nama_pihak, tgl_transaksi, jumlah, keterangan } = req.body;
  const no_transaksi = 'IN-' + Date.now(); 


  db.query('INSERT INTO supplier (nama_supplier, alamat, no_telp) VALUES (?, "-", "-")', [nama_pihak || 'Supplier Internal'], (err, supRes) => {
    if (err) return res.status(500).json({ error: err.message });
    

    db.query('INSERT INTO barang_masuk SET ?', { no_transaksi, kode_barang, id_supplier: supRes.insertId, tgl_transaksi, jumlah, keterangan }, (err2) => {
      if (err2) return res.status(500).json({ error: err2.message });
      db.query('UPDATE barang SET stok = stok + ? WHERE kode_barang = ?', [jumlah, kode_barang], (err3) => {
        if (err3) return res.status(500).json({ error: err3.message });
        res.json({ message: 'Restock berhasil' });
      });
    });
  });
});

// 4. ENDPOINT TRANSAKSI KELUAR
app.post('/api/barang-keluar', (req, res) => {
  const { kode_barang, nama_pihak, tgl_transaksi, jumlah, keterangan } = req.body;
  const no_transaksi = 'OUT-' + Date.now();

  db.query('SELECT stok FROM barang WHERE kode_barang = ?', [kode_barang], (err, results) => {
    if (err || results.length === 0) return res.status(500).json({ error: 'Barang tidak ditemukan' });
    if (results[0].stok < jumlah) return res.status(400).json({ error: 'Stok tidak cukup' });

    db.query('INSERT INTO konsumen (nama_konsumen, alamat, no_telp) VALUES (?, "-", "-")', [nama_pihak || 'Konsumen Umum'], (err2, konRes) => {
      if (err2) return res.status(500).json({ error: err2.message });

      db.query('INSERT INTO barang_keluar SET ?', { no_transaksi, kode_barang, id_konsumen: konRes.insertId, tgl_transaksi, jumlah, keterangan }, (err3) => {
        if (err3) return res.status(500).json({ error: err3.message });
        db.query('UPDATE barang SET stok = stok - ? WHERE kode_barang = ?', [jumlah, kode_barang], (err4) => {
          if (err4) return res.status(500).json({ error: err4.message });
          res.json({ message: 'Penjualan berhasil' });
        });
      });
    });
  });
});

// 5. ENDPOINT LAPORAN
app.get('/api/laporan/masuk', (req, res) => {
  const q = `SELECT bm.*, b.nama_barang, s.nama_supplier AS pihak_terkait 
             FROM barang_masuk bm 
             JOIN barang b ON bm.kode_barang = b.kode_barang 
             JOIN supplier s ON bm.id_supplier = s.id_supplier ORDER BY tgl_transaksi DESC`;
  db.query(q, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

app.get('/api/laporan/keluar', (req, res) => {
  const q = `SELECT bk.*, b.nama_barang, k.nama_konsumen AS pihak_terkait 
             FROM barang_keluar bk 
             JOIN barang b ON bk.kode_barang = b.kode_barang 
             JOIN konsumen k ON bk.id_konsumen = k.id_konsumen ORDER BY tgl_transaksi DESC`;
  db.query(q, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// 6. ENDPOINT HAPUS BARANG
app.delete('/api/barang/:kode', (req, res) => {
  const { kode } = req.params;

  db.query('DELETE FROM barang_masuk WHERE kode_barang = ?', [kode], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    
    db.query('DELETE FROM barang_keluar WHERE kode_barang = ?', [kode], (err2) => {
      if (err2) return res.status(500).json({ error: err2.message });
      
      db.query('DELETE FROM barang WHERE kode_barang = ?', [kode], (err3) => {
        if (err3) return res.status(500).json({ error: err3.message });
        res.json({ message: 'Data barang berhasil dihapus sepenuhnya' });
      });
    });
  });
});
// 7. ENDPOINT EKSPOR EXCEL
app.get('/api/laporan/export', async (req, res) => {
  try {
    const workbook = new ExcelJS.Workbook();
    const sheetMasuk = workbook.addWorksheet('Barang Masuk');
    const sheetKeluar = workbook.addWorksheet('Barang Keluar');

    const columns = [
      { header: 'Tgl Transaksi', key: 'tgl', width: 25 },
      { header: 'No Transaksi', key: 'no', width: 20 },
      { header: 'Nama Barang', key: 'nama', width: 30 },
      { header: 'Pihak Terkait', key: 'pihak', width: 25 },
      { header: 'Jumlah (Unit)', key: 'jumlah', width: 15 }
    ];
    sheetMasuk.columns = columns;
    sheetKeluar.columns = columns;

    db.query(`SELECT bm.*, b.nama_barang, s.nama_supplier AS pihak_terkait FROM barang_masuk bm JOIN barang b ON bm.kode_barang = b.kode_barang JOIN supplier s ON bm.id_supplier = s.id_supplier ORDER BY tgl_transaksi DESC`, (err, resMasuk) => {
      if (err) return res.status(500).json({ error: err.message });
      
      resMasuk.forEach(row => {
        sheetMasuk.addRow({ tgl: row.tgl_transaksi, no: row.no_transaksi, nama: row.nama_barang, pihak: row.pihak_terkait, jumlah: row.jumlah });
      });

      db.query(`SELECT bk.*, b.nama_barang, k.nama_konsumen AS pihak_terkait FROM barang_keluar bk JOIN barang b ON bk.kode_barang = b.kode_barang JOIN konsumen k ON bk.id_konsumen = k.id_konsumen ORDER BY tgl_transaksi DESC`, async (err2, resKeluar) => {
        if (err2) return res.status(500).json({ error: err2.message });
        
        resKeluar.forEach(row => {
          sheetKeluar.addRow({ tgl: row.tgl_transaksi, no: row.no_transaksi, nama: row.nama_barang, pihak: row.pihak_terkait, jumlah: row.jumlah });
        });

        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', 'attachment; filename="Laporan_CosyCouch.xlsx"');
        
        await workbook.xlsx.write(res);
        res.end();
      });
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => console.log('Server berjalan di port 3000'));