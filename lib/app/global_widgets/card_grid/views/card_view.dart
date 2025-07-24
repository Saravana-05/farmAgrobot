import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/card_controller.dart';

class CardGrid extends GetView<CardController> {
  final List<Widget> cards;

  const CardGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 40.0,
          mainAxisSpacing: 2.0,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return cards[index];
        },
      ),
    );
  }
}

class SmallCard extends GetView<CardController> {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;
  final bool isDisabled;
  final VoidCallback? onDisabledTap;
  final String? cardId; // Optional unique identifier for the card

  const SmallCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.isDisabled = false,
    this.onDisabledTap,
    this.cardId,
  });

  @override
  Widget build(BuildContext context) {
    // Use cardId if provided, otherwise use title as identifier
    final String identifier = cardId ?? title;
    
    return Obx(() {
      final bool cardIsDisabled = isDisabled || controller.isCardDisabled(identifier);
      
      return GestureDetector(
        onTap: () => controller.handleCardTap(identifier, onTap, onDisabledTap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              elevation: 3.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              color: cardIsDisabled ? Colors.grey : color,
              child: Container(
                width: 50.0,
                height: 50.0,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 25.0),
                    const SizedBox(height: 2.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      );
    });
  }
}