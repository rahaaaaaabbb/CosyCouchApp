import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';


const String baseUrl = 'http://127.0.0.1:3000';


const Color bgCream = Color(0xFFFDFBF7);
const Color nudeGold = Color(0xFFD2A679);
const Color mochaBrown = Color(0xFF4A3320);
const Color softShadow = Color(0x1A000000);

void main() {
  runApp(const CosyCouchApp());
}

class CosyCouchApp extends StatelessWidget {
  const CosyCouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CosyCouch Premium',
      theme: ThemeData(
        scaffoldBackgroundColor: bgCream,
        primaryColor: mochaBrown,
        fontFamily: 'Segoe UI',
        appBarTheme: const AppBarTheme(
          backgroundColor: bgCream,
          elevation: 0,
          iconTheme: IconThemeData(color: mochaBrown),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 1. HALAMAN LOGIN 
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('$baseUrl/api/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning':
              'true',
        },
        body: json.encode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selamat datang, ${data['user']['nama_lengkap']}!'),
            ),
          );

          if (data['user']['role'] == 'Karyawan') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardKaryawan(
                  namaKaryawan: data['user']['nama_lengkap'],
                ),
              ),
            );
          } else if (data['user']['role'] == 'Pemilik') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DashboardPemilik(namaPemilik: data['user']['nama_lengkap']),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login gagal. Periksa username/password.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error API: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag, size: 64, color: nudeGold),
              const SizedBox(height: 16),
              const Text(
                'COSYCOUCH',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: mochaBrown,
                  letterSpacing: 4,
                ),
              ),
              const Text(
                'PREMIUM INVENTORY',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 6,
                  color: nudeGold,
                ),
              ),
              const SizedBox(height: 64),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person_outline, color: nudeGold),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, color: nudeGold),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mochaBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                    shadowColor: mochaBrown.withOpacity(0.5),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'MASUK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. DASHBOARD KARYAWAN (LUXURY HOME)
// ==========================================
class DashboardKaryawan extends StatefulWidget {
  final String namaKaryawan;
  const DashboardKaryawan({super.key, required this.namaKaryawan});

  @override
  State<DashboardKaryawan> createState() => _DashboardKaryawanState();
}

class _DashboardKaryawanState extends State<DashboardKaryawan> {
  List _barangList = [];
  List _filteredBarangList = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  File? _imageFile;
  Uint8List? _webImage;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _fetchBarang();
  }

  Future<void> _fetchBarang() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/barang'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _barangList = json.decode(response.body);
          _jalankanPencarian(_searchController.text);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _jalankanPencarian(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        _filteredBarangList = List.from(_barangList);
      } else {
        _filteredBarangList = _barangList.where((item) {
          final namaTas = item['nama_barang'].toString().toLowerCase();
          final kodeBarang = item['kode_barang'].toString().toLowerCase();
          final input = keyword.toLowerCase();
          return namaTas.contains(input) || kodeBarang.contains(input);
        }).toList();
      }
    });
  }

  Future<void> _pilihFoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        var f = await pickedFile.readAsBytes();
        setState(() {
          _webImage = f;
          _imageFile = null;
          _fileName = pickedFile.name;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImage = null;
          _fileName = pickedFile.name;
        });
      }
    }
  }

  void _tampilkanDialogTambahBarang() {
    final kodeCtrl = TextEditingController();
    final namaCtrl = TextEditingController();
    final varianCtrl = TextEditingController();
    final kategoriCtrl = TextEditingController();
    final hBeliCtrl = TextEditingController();
final hJualCtrl = TextEditingController(); // BARU
final stokCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: bgCream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Tambah Koleksi Baru',
              style: TextStyle(color: mochaBrown, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await _pilihFoto();
                      setStateDialog(() {});
                    },
                    child: Center(
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: const [
                            BoxShadow(
                              color: softShadow,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: _webImage != null
                              ? Image.memory(_webImage!, fit: BoxFit.cover)
                              : _imageFile != null
                              ? Image.file(_imageFile!, fit: BoxFit.cover)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 32,
                                      color: nudeGold,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Upload',
                                      style: TextStyle(
                                        color: nudeGold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: kodeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kode Barang',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: namaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tas',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: varianCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Varian/Warna',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: kategoriCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: hBeliCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga (Rp)',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextField(
  controller: hJualCtrl,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
    labelText: 'Harga Jual (Rp)',
    border: UnderlineInputBorder(),
  ),
),
                  TextField(
                    controller: stokCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stok Awal',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: nudeGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  try {
                    var req = http.MultipartRequest(
                      'POST',
                      Uri.parse('$baseUrl/api/barang-foto'),
                    );

                    req.headers['ngrok-skip-browser-warning'] = 'true';

                    req.fields['kode_barang'] = kodeCtrl.text;
                    req.fields['nama_barang'] = namaCtrl.text;
                    req.fields['varian_warna'] = varianCtrl.text.isEmpty
                        ? 'Default'
                        : varianCtrl.text;
                    req.fields['kategori'] = kategoriCtrl.text.isEmpty
                        ? 'Umum'
                        : kategoriCtrl.text;
                    req.fields['harga_beli'] = hBeliCtrl.text;
                    req.fields['harga_jual'] = hJualCtrl.text;
                    req.fields['stok'] = stokCtrl.text;
                    req.fields['batas_minimum'] = '5';

                    if (kIsWeb && _webImage != null) {
                      req.files.add(
                        http.MultipartFile.fromBytes(
                          'foto',
                          _webImage!,
                          filename: _fileName ?? 'foto.jpg',
                        ),
                      );
                    } else if (_imageFile != null) {
                      req.files.add(
                        await http.MultipartFile.fromPath(
                          'foto',
                          _imageFile!.path,
                        ),
                      );
                    }

                    var res = await req.send();
                    if (res.statusCode == 200) {
                      _fetchBarang();
                      _imageFile = null;
                      _webImage = null;
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Barang berhasil disimpan!'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _goToDetail(Map item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: item),
      ),
    );
    if (result == true) _fetchBarang();
  }

  Future<void> _hapusBarang(String kodeBarang) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/barang/$kodeBarang'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        _fetchBarang();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang berhasil dihapus!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  Widget _buildProductCard(Map item) {
    String imageUrl = item['foto'] != null
        ? '$baseUrl/uploads/${item['foto']}'
        : 'https://via.placeholder.com/150';

    // --- FITUR DISMISSIBLE (SWIPE TO DELETE) ---
    return Dismissible(
      key: Key(item['kode_barang'].toString()),
      direction: DismissDirection.up,
      background: Container(
        margin: const EdgeInsets.only(right: 24, top: 50),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 30),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_sweep, color: Colors.white, size: 40),
            Text('HAPUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: bgCream,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Konfirmasi Hapus', style: TextStyle(color: mochaBrown)),
            content: Text('Yakin ingin menghapus ${item['nama_barang']} beserta riwayat transaksinya?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _hapusBarang(item['kode_barang'].toString());
      },
      
      child: GestureDetector(
        onTap: () => _goToDetail(item),
        child: Container(
          width: 220,
          margin: const EdgeInsets.only(right: 24, top: 50),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: 260,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: mochaBrown,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: mochaBrown.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item['stok'] <= item['batas_minimum']
                            ? Colors.redAccent
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Stok: ${item['stok']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['nama_barang'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['kategori'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Rp ${item['harga_beli']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: mochaBrown,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -60,
                child: Container(
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    boxShadow: const [
                      BoxShadow(
                        color: softShadow,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      imageUrl,
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: nudeGold,
        onPressed: _tampilkanDialogTambahBarang,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: nudeGold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: mochaBrown,
                              child: Icon(Icons.person, color: nudeGold),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Petugas Shift',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_user,
                                      color: nudeGold,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.namaKaryawan,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: mochaBrown,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: softShadow,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.logout, color: mochaBrown),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'COSYCOUCH',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: mochaBrown,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      '"Carry Comfort, Carry Confidence."',
                      style: TextStyle(
                        fontSize: 14,
                        color: nudeGold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: softShadow,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _jalankanPencarian,
                        decoration: InputDecoration(
                          hintText: 'Cari koleksi tas atau kode...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search, color: nudeGold),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Inventory Terkini',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: mochaBrown,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 340,
                      child: _filteredBarangList.isEmpty
                          ? Center(
                              child: Text(
                                'Barang tidak ditemukan',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              itemCount: _filteredBarangList.length,
                              itemBuilder: (context, index) =>
                                  _buildProductCard(_filteredBarangList[index]),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ==========================================
// 3. PRODUCT DETAIL (FORM TRANSAKSI KASIR)
// ==========================================
class ProductDetailScreen extends StatefulWidget {
  final Map product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _jumlahCtrl = TextEditingController(text: '1');
  final TextEditingController _ketCtrl = TextEditingController();
  final TextEditingController _pihakCtrl = TextEditingController();

  void _ubahJumlah(int nilai) {
    int current = int.tryParse(_jumlahCtrl.text) ?? 1;
    if (current + nilai > 0) {
      setState(() => _jumlahCtrl.text = (current + nilai).toString());
    }
  }

  Future<void> _prosesTransaksi(String tipe) async {
    final endpoint = tipe == 'jual'
        ? '/api/barang-keluar'
        : '/api/barang-masuk';
    final jumlah = int.tryParse(_jumlahCtrl.text) ?? 0;

    if (jumlah <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jumlah tidak valid!')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', 
        },
        body: json.encode({
  'kode_barang': widget.product['kode_barang'],
  'nama_pihak': _pihakCtrl.text, // Mengirimkan teks manual
  'tgl_transaksi': DateTime.now().toString().substring(0, 19),
  'jumlah': jumlah,
  'keterangan': _ketCtrl.text,
}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tipe == 'jual' ? 'Penjualan Berhasil!' : 'Restock Berhasil!',
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final data = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(data['error'])));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error API: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = widget.product['foto'] != null
        ? '$baseUrl/uploads/${widget.product['foto']}'
        : 'https://via.placeholder.com/150';

    return Scaffold(
      backgroundColor: bgCream,
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.40,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: mochaBrown,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(50),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    height: 240,
                    width: 240,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 15),
                        ),
                      ],
                    ),
                    // PERBAIKAN: Gunakan ClipOval + Image.network agar bisa pasang header
                    child: ClipOval(
                      child: Image.network(
                        imageUrl,
                        headers: const {'ngrok-skip-browser-warning': 'true'},
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 50),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 70),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.product['nama_barang'],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: mochaBrown,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: nudeGold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Stok: ${widget.product['stok']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Spesifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: mochaBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kode: ${widget.product['kode_barang']} | Kategori: ${widget.product['kategori']} |\nVarian: ${widget.product['varian_warna']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Kelola Transaksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: mochaBrown,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // --- PASTE KODE DI SINI ---
                    TextField(
                      controller: _pihakCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ketik Nama Konsumen / Supplier',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // --- AKHIR PASTE ---

                    TextField(
                      controller: _ketCtrl,
                      decoration: InputDecoration(
                        hintText: 'Keterangan Tambahan (Opsional)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harga Satuan',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Rp ${widget.product['harga_beli']}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: mochaBrown,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove,
                                  color: mochaBrown,
                                ),
                                onPressed: () => _ubahJumlah(-1),
                              ),
                              SizedBox(
                                width: 40,
                                child: TextField(
                                  controller: _jumlahCtrl,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: mochaBrown,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: mochaBrown),
                                onPressed: () => _ubahJumlah(1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: softShadow,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: mochaBrown, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => _prosesTransaksi('jual'),
                    child: const Text(
                      'Jual (-)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: mochaBrown,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mochaBrown,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                      shadowColor: mochaBrown.withOpacity(0.5),
                    ),
                    onPressed: () => _prosesTransaksi('restock'),
                    child: const Text(
                      'Restock (+)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. DASHBOARD PEMILIK & LAPORAN
// ==========================================
class DashboardPemilik extends StatefulWidget {
  final String namaPemilik;
  const DashboardPemilik({super.key, required this.namaPemilik});

  @override
  State<DashboardPemilik> createState() => _DashboardPemilikState();
}

class _DashboardPemilikState extends State<DashboardPemilik> {
  List _barangList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBarang();
  }

  Future<void> _fetchBarang() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/barang'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _barangList = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final barangKritis = _barangList
        .where((item) => item['stok'] <= item['batas_minimum'])
        .toList();

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard Owner', style: TextStyle(fontSize: 12)),
            Text(
              widget.namaPemilik,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: nudeGold))
          : RefreshIndicator(
              onRefresh: _fetchBarang,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: softShadow,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.inventory_2,
                                color: nudeGold,
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${_barangList.length}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: mochaBrown,
                                ),
                              ),
                              const Text(
                                'Total Produk',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: barangKritis.isNotEmpty
                                ? Colors.red[50]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: barangKritis.isNotEmpty
                                ? Border.all(color: Colors.red.shade200)
                                : null,
                            boxShadow: const [
                              BoxShadow(
                                color: softShadow,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: barangKritis.isNotEmpty
                                    ? Colors.red
                                    : Colors.grey,
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${barangKritis.length}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: barangKritis.isNotEmpty
                                      ? Colors.red
                                      : mochaBrown,
                                ),
                              ),
                              const Text(
                                'Stok Kritis',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LaporanScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: mochaBrown,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: mochaBrown.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Lihat Laporan Transaksi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Pantauan Seluruh Stok',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: mochaBrown,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._barangList.map((item) {
                    final isKritis = item['stok'] <= item['batas_minimum'];
                    String imageUrl = item['foto'] != null
                        ? '$baseUrl/uploads/${item['foto']}'
                        : 'https://via.placeholder.com/150';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: softShadow,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                        border: isKritis
                            ? Border.all(color: Colors.red.shade300, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              imageUrl,
                              headers: const {
                                'ngrok-skip-browser-warning': 'true',
                              },
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nama_barang'],
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: mochaBrown,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['kode_barang']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item['stok']}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isKritis
                                      ? Colors.red
                                      : Colors.green[700],
                                ),
                              ),
                              Text(
                                'Unit',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List _masukList = [];
  List _keluarList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLaporan();
  }

  Future<void> _fetchLaporan() async {
    try {
      final resMasuk = await http.get(
        Uri.parse('$baseUrl/api/laporan/masuk'),
        headers: {
          'ngrok-skip-browser-warning':
              'true',
        },
      );

      final resKeluar = await http.get(
        Uri.parse(
          '$baseUrl/api/laporan/keluar',
        ),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Content-Type': 'application/json',
        },
      );

      if (resMasuk.statusCode == 200 && resKeluar.statusCode == 200) {
        setState(() {
          _masukList = json.decode(resMasuk.body);
          _keluarList = json.decode(resKeluar.body);
          _isLoading = false;
        });
      }
    } catch (e) {}
  }

 Widget _buildLogCard(Map item, bool isMasuk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: softShadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMasuk ? Colors.green[50] : Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
              color: isMasuk ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama_barang'], 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: mochaBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pihak: ${item['pihak_terkait']}', 
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isMasuk ? '+${item['jumlah']}' : '-${item['jumlah']}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isMasuk ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['tgl_transaksi'] != null 
                    ? item['tgl_transaksi'].toString().substring(0, 10)
                    : '-',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: const Text(
          'Laporan Digital',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        
        // --- BLOK ACTIONS UNDUH EXCEL ---
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: nudeGold),
            tooltip: 'Unduh Excel',
            onPressed: () async {
              final Uri url = Uri.parse('$baseUrl/api/laporan/export');
              if (!await launchUrl(url)) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal mengunduh file Excel')),
                  );
                }
              }
            },
          ),
        ],
        
        bottom: TabBar(
          controller: _tabController,
          labelColor: nudeGold,
          unselectedLabelColor: Colors.grey,
          indicatorColor: nudeGold,
          tabs: const [
            Tab(icon: Icon(Icons.call_received), text: 'Barang Masuk'),
            Tab(icon: Icon(Icons.call_made), text: 'Barang Keluar'),
          ],
        ),
      ),
      
      // BODY MILIK SCAFFOLD
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: nudeGold))
          : TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _masukList.length,
                  itemBuilder: (c, i) => _buildLogCard(_masukList[i], true),
                ),
                ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _keluarList.length,
                  itemBuilder: (c, i) => _buildLogCard(_keluarList[i], false),
                ),
              ],
            ),
    );
  }
    }