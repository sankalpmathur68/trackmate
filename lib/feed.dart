import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

class UploadedImage {
  String id;
  String imageUrl; // The URL of the image in Firebase Cloud Storage
  String userId; // The ID of the user who uploaded the image
  String caption;
  DateTime timestamp;

  UploadedImage({
    required this.id,
    required this.imageUrl,
    required this.userId,
    required this.caption,
    required this.timestamp,
  });
}

final userId = FirebaseAuth.instance.currentUser?.uid;

class DisplayImagesPage extends StatelessWidget {
  Stream<List<UploadedImage>> _fetchUploadedImagesStream() {
    final databaseRef =
        FirebaseDatabase.instance.reference().child('uploaded_images');
    return databaseRef.onValue.map((event) {
      final imagesMap = (event.snapshot.value ?? {}) as Map<dynamic, dynamic>;
      return imagesMap.entries.map((entry) {
        final data = entry.value as Map<dynamic, dynamic>;
        return UploadedImage(
          id: entry.key,
          imageUrl: data['imageUrl'],
          userId: data['userId'],
          caption: data['caption'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
        );
      }).toList();
    });
  }

  _deleteImage(String imageId, imageUrl) async {
    if (userId == null) {
      print('User not authenticated.');
      return;
    }

    final databaseRef =
        FirebaseDatabase.instance.ref().child('uploaded_images');
    final userImageRef = databaseRef.child(imageId);
    await userImageRef.remove();
    await firebase_storage.FirebaseStorage.instance
        .refFromURL(imageUrl)
        .delete();
    // final snapshot = await userImageRef.once();
    // final imageData = snapshot.value as Map<dynamic, dynamic>;

    // if (imageData['userId'] == userId) {
    //   await userImageRef.remove();
    //
    //
    //   print('Image deleted successfully.');
    // } else {
    //   print('You are not the owner of this image.');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<UploadedImage>>(
        stream: _fetchUploadedImagesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
              ],
            ));
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final imagesList = snapshot.data ?? [];
            if (imagesList.isEmpty) {
              return Center(
                child: Text('No Images Found.'),
              );
            }

            return ListView.builder(
              itemCount: imagesList.length,
              itemBuilder: (context, index) {
                final image = imagesList[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'User ID: ${image.userId}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (FirebaseAuth.instance.currentUser?.uid ==
                                image
                                    .userId) // Show delete button only to the owner
                              GestureDetector(
                                onTap: () =>
                                    _deleteImage(image.id, image.imageUrl),
                                child: Icon(Icons.delete),
                              ),
                          ],
                        ),
                      ),
                      Image.network(
                        image.imageUrl,
                        cacheHeight: 500,
                        cacheWidth: 500,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          image.caption,
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
