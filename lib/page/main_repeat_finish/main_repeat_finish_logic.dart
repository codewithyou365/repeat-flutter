import 'package:get/get.dart';

import 'main_repeat_finish_state.dart';

class MainRepeatFinishLogic extends GetxController {
  final MainRepeatFinishState state = MainRepeatFinishState();

  @override
  void onInit() async{
    super.onInit();
    // TODO await Db().db.scheduleDao.clearCurrent();
  }
}
