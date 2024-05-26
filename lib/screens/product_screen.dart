import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductScreen extends StatelessWidget {
  final String productId;

  ProductScreen({required this.productId});

  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();

  Future<String?> _getUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return userDoc['role'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Product')
            .doc(productId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.data!.exists) {
            return Center(child: Text('Product not found'));
          }

          var productData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (productData.containsKey('imageUrl') &&
                    productData['imageUrl'] != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        productData['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return Text('Error loading image');
                        },
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    productData['name'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    '\$${productData['price']}',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    productData['category'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  productData['description'],
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16),
                FutureBuilder<String?>(
                  future: _getUserRole(),
                  builder: (context, roleSnapshot) {
                    if (!roleSnapshot.hasData || roleSnapshot.data == 'Admin') {
                      return Container(); // Do not show review button
                    } else {
                      return Center(
                        child: ElevatedButton(
                          onPressed: () => _showReviewDialog(context),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: Text('Add Review'),
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Product')
                      .doc(productId)
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
                    double avgRating =
                        reviews.isNotEmpty ? totalRating / reviews.length : 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Average Rating: ${avgRating.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Reviews:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        ...reviews.map((review) {
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text('Rating: ${review['rating']}'),
                              subtitle: Text(review['comment']),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ratingController,
                decoration: InputDecoration(
                  labelText: 'Rating (out of 5)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _reviewController,
                decoration: InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _addReview(context),
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _addReview(BuildContext context) async {
    final rating = double.tryParse(_ratingController.text) ?? 0.0;
    final comment = _reviewController.text;

    if (rating < 0 || rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rating must be between 0 and 5')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('Product')
        .doc(productId)
        .collection('reviews')
        .add({
      'rating': rating,
      'comment': comment,
    });

    Navigator.of(context).pop();
    _ratingController.clear();
    _reviewController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Review submitted successfully')),
    );
  }
}
