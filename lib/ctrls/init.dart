import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../ctrls/ctrls.dart';

Future<void> init() async {
  await GetStorage.init('MyStorage');
  Get.put((ApiService()), permanent: true);
}