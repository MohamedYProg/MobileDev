import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_screen.dart';
import 'cart_screen.dart';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  String? userRole;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //Esht5l ya rambo ya 3gl

  final List<String> _categories = [
    "Sanitation",
    "Toys",
    "Clothes",
    "Food",
    "Skin Care"
  ];
  String selectedCategory = 'Sanitation';

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userRole = userDoc['role'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product List'),
        backgroundColor: Colors.blueAccent,
        actions: [
          if (userRole != 'Admin')
            IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartScreen()),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (userRole == 'Admin') ...[
                Text(
                  'Add a New Product',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  labelText: 'Product Name',
                  icon: Icons.label,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _priceController,
                  labelText: 'Product Price',
                  icon: Icons.attach_money,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  labelText: 'Product Description',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _imageUrlController,
                  labelText: 'Product Image URL',
                  icon: Icons.image,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    addProduct(
                      _nameController.text,
                      double.tryParse(_priceController.text) ?? 0.0,
                      _descriptionController.text,
                      _imageUrlController.text,
                      selectedCategory,
                      userid: _auth.currentUser!.uid,
                    );
                    _nameController.clear();
                    _priceController.clear();
                    _descriptionController.clear();
                    _imageUrlController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Add Product',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 32),
              ],
              Text(
                'Product List',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Product')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No products found'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Product')
                            .doc(doc.id)
                            .collection('reviews')
                            .snapshots(),
                        builder: (context, reviewSnapshot) {
                          if (!reviewSnapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final reviews = reviewSnapshot.data!.docs;
                          double totalRating = 0;
                          for (var review in reviews) {
                            totalRating += review['rating'];
                          }
                          double avgRating = reviews.isNotEmpty
                              ? totalRating / reviews.length
                              : 0;

                          return Card(
                            elevation: 5,
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: ListTile(
                              title: Text(data['name'] ?? 'No Name'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '\$${data['price']?.toStringAsFixed(2) ?? '0.00'}'),
                                  Text(data['description'] ?? 'No Description'),
                                  Text('Reviews: ${reviews.length}'),
                                  Text(
                                      'Rating: ${avgRating.toStringAsFixed(1)}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (userRole == 'Admin') ...[
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () {
                                        removeProduct(doc.id);
                                      },
                                    ),
                                  ],
                                  if (userRole == 'User') ...[
                                    IconButton(
                                      icon: Icon(Icons.add_shopping_cart,
                                          color: Colors.green),
                                      onPressed: () {
                                        addToCart(doc.id);
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductScreen(productId: doc.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Future<void> addProduct(
    String name,
    double price,
    String description,
    String imageUrl,
    String selectedCategory, {
    required String userid,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('Product').add({
        'name': name,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'review': [], // Empty list for reviews
        'rating': 0.0, // Initial rating as 0.0
        'category': null, // Category set to null
        'comments': [], // Empty list for comments
        'userId': userid, // Set user ID
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product')),
      );
    }
  }

  Future<void> removeProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Product')
          .doc(productId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove product')),
      );
    }
  }

  Future<void> addToCart(String productId) async {
    try {
      DocumentSnapshot productDoc = await FirebaseFirestore.instance
          .collection('Product')
          .doc(productId)
          .get();
      Map<String, dynamic> data = productDoc.data() as Map<String, dynamic>;
      await FirebaseFirestore.instance.collection('Cart').add({
        'productId': productId,
        'productName': data['name'],
        'price': data['price'],
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product added to cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product to cart')),
      );
    }
  }
}
