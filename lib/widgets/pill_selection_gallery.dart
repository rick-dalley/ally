import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PillSelectionGallery extends StatelessWidget {
  final List<String> images;
  const PillSelectionGallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => Navigator.pop(context, images[index]),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
            child: CachedNetworkImage(imageUrl: images[index], fit: BoxFit.contain),
          ),
        );
      },
    );
  }
}
