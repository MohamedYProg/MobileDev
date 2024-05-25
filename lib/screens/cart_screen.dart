import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CollectionReference cartRef =
      FirebaseFirestore.instance.collection('Cart');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No items in the cart'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              return Card(
                elevation: 5,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: ListTile(
                  title: Text(doc['productName']),
                  subtitle: Text('\$${doc['price']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      removeFromCart(doc.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      await cartRef.doc(cartItemId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item removed from cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item')),
      );
    }
  }
}