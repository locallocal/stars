import 'package:flutter/material.dart';

class ImageGenerationPanel extends StatelessWidget {
  final List<String> supportedSizes;
  final String selectedSize;
  final Function(String) onSizeSelected;

  const ImageGenerationPanel({
    super.key,
    required this.supportedSizes,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        supportedSizes.map((size) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(size),
                              selected: selectedSize == size,
                              onSelected: (selected) {
                                if (selected) {
                                  onSizeSelected(size);
                                }
                              },
                              avatar:
                                  selectedSize == size
                                      ? Icon(
                                        Icons.image,
                                        size: 16,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      )
                                      : null,
                              shape: StadiumBorder(
                                side: BorderSide(color: Colors.transparent),
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                              labelStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
