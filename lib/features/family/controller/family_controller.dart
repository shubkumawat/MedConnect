import 'package:get/get.dart';
import '../model/family_member_model.dart';
import '../../home/controller/home_controller.dart';

class FamilyController extends GetxController {
  var familyMembers = <FamilyMemberModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadDummyData();
  }

  void _loadDummyData() {
    familyMembers.value = [
      FamilyMemberModel(id: '1', name: 'John Doe', relation: 'Self', bloodGroup: 'O+', isSelf: true),
      FamilyMemberModel(id: '2', name: 'Jane Doe', relation: 'Spouse', bloodGroup: 'A+'),
      FamilyMemberModel(id: '3', name: 'Junior Doe', relation: 'Son', bloodGroup: 'O+'),
    ];
  }

  void addFamilyMember(FamilyMemberModel member) {
    familyMembers.add(member);
  }

  void deleteMember(String id) {
    familyMembers.removeWhere((m) => m.id == id && !m.isSelf);
  }

  void switchActivePatient(FamilyMemberModel member) {
    Get.find<HomeController>().switchPatient(member);
  }
}
