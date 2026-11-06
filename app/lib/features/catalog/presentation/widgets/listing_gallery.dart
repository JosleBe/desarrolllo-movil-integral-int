import 'package:flutter/material.dart';

/// Galería de imágenes de una publicación (HU-09).
///
/// La subida y el almacenamiento real en Cloud (RNF-06) son trabajo del
/// backend. Aquí se muestran las imágenes si hay URLs; mientras tanto, un
/// placeholder visual representa cada foto.
class ListingGallery extends StatelessWidget {
  const ListingGallery({required this.imageUrls, super.key});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (imageUrls.isEmpty) {
      return _Placeholder(
        color: scheme.surfaceContainerHighest,
        iconColor: scheme.outline,
        label: 'Sin imágenes',
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final url = imageUrls[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                semanticLabel: 'Imagen ${index + 1} del artículo',
                errorBuilder: (context, error, stack) => _Placeholder(
                  color: scheme.surfaceContainerHighest,
                  iconColor: scheme.outline,
                  label: 'Imagen ${index + 1}',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.color,
    required this.iconColor,
    required this.label,
  });

  final Color color;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 48, color: iconColor),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: iconColor)),
        ],
      ),
    );
  }
}
