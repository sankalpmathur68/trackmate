import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ImageUploadPage extends StatefulWidget {
  ImageUploadPage({required this.lat, required this.long});
  double lat;
  double long;
  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  XFile? _imageFile;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  _captureImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      _imageFile = image;
    });
  }

  _uploadImage() async {
    if (_imageFile == null) return;

    final storageRef = firebase_storage.FirebaseStorage.instance
        .ref()
        .child('images/${DateTime.now().millisecondsSinceEpoch}.png');
    final uploadTask = storageRef.putFile(File(_imageFile!.path));

    final snapshot = await uploadTask.whenComplete(() {});

    if (snapshot.state == firebase_storage.TaskState.success) {
      final imageUrl = await snapshot.ref.getDownloadURL();
      final userId =
          '$uid'; // Replace this with the actual user ID if you have user authentication implemented
      final caption =
          'Latitude: ${widget.lat} || Longitude: ${widget.long}'; // You can get this from the user as well

      final databaseRef =
          FirebaseDatabase.instance.reference().child('uploaded_images');
      final newImageRef = databaseRef.push();
      await newImageRef.set({
        'imageUrl': imageUrl,
        'userId': userId,
        'caption': caption,
        'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
      });

      setState(() {
        _imageFile = null;
      });

      print('Image uploaded.');
    } else {
      print('Image upload failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _imageFile == null
            ? Text('No Image Selected')
            : Image.file(File(_imageFile!.path)),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: _captureImage,
            tooltip: 'Capture Image',
            child: Icon(Icons.camera),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: _uploadImage,
            tooltip: 'Upload Image',
            child: Icon(Icons.cloud_upload),
          ),
        ],
      ),
    );
  }
}
