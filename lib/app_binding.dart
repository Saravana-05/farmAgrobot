import 'package:get/get.dart';
import 'app/data/services/messages/message_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize MessageService as a permanent service
    Get.put(MessageService(), permanent: true);
  }
}