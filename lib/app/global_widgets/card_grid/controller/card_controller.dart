import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CardController extends GetxController {
  var cardStates = <String, bool>{}.obs;
  
  void setCardDisabled(String cardId, bool isDisabled) {
    cardStates[cardId] = isDisabled;
  }
  
  bool isCardDisabled(String cardId) {
    return cardStates[cardId] ?? false;
  }
  
  void handleCardTap(String cardId, VoidCallback? onTap, VoidCallback? onDisabledTap) {
    if (isCardDisabled(cardId)) {
      onDisabledTap?.call();
    } else {
      onTap?.call();
    }
  }
}