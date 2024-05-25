import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(hintText: 'Product Name'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: InputDecoration(hintText: 'Product Price'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration:
                        InputDecoration(hintText: 'Product Description'),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    addProduct(
                        _nameController.text,
                        double.tryParse(_priceController.text)!,
                        _descriptionController.text);
                    _nameController.clear();
                    _priceController.clear();
                    _descriptionController.clear();
                  },
                  child: Text('Add Product'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('Product').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No products found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(doc['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('\$${doc['price']}'),
                          Text(doc['description']),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          removeProduct(doc.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> addProduct(String name, double price, String description) async {
    await FirebaseFirestore.instance.collection('Product').add({
      'name': name,
      'price': price,
      'description': description,
    });
  }

  Future<void> removeProduct(String productId) async {
    await FirebaseFirestore.instance
        .collection('Product')
        .doc(productId)
        .delete();
  }
}
