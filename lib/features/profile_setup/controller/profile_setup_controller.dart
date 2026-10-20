import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../model/profile_model.dart';
import '../../../app/routes/app_routes.dart';

class ProfileSetupController extends GetxController {
  var currentStep = 1.obs;
  var profile = ProfileModel().obs;

  // Controllers for Step 1
  final nameController = TextEditingController();
  final nationalityController = TextEditingController(text: 'India');
  
  // Controllers for Step 2
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final allergyController = TextEditingController();

  // Controllers for Step 3
  final emergencyNameController = TextEditingController();
  final emergencyRelationController = TextEditingController();
  final emergencyMobileController = TextEditingController();
  final homeCityController = TextEditingController();
  final homeStateController = TextEditingController();
  final insuranceController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Initialize with default values if any
  }

  void updateGender(String gender) {
    profile.update((val) {
      val?.gender = gender;
    });
  }

  void updateDob(DateTime dob) {
    profile.update((val) {
      val?.dob = dob;
    });
  }

  void updateBloodGroup(String? bg) {
    profile.update((val) {
      val?.bloodGroup = bg;
    });
  }

  void toggleWeightUnit() {
    profile.update((val) {
      val?.weightUnitKg = !(val.weightUnitKg);
    });
  }

  void toggleHeightUnit() {
    profile.update((val) {
      val?.heightUnitCm = !(val.heightUnitCm);
    });
  }

  void addAllergy(String allergy) {
    if (allergy.isNotEmpty) {
      profile.update((val) {
        val?.allergies.add(allergy);
      });
      allergyController.clear();
    }
  }

  void removeAllergy(String allergy) {
    profile.update((val) {
      val?.allergies.remove(allergy);
    });
  }

  void setChronicDisease(bool value) {
    profile.update((val) {
      val?.hasChronicDisease = value;
    });
  }

  void setOrganDonor(bool value) {
    profile.update((val) {
      val?.isOrganDonor = value;
    });
  }

  void nextStep() {
    if (currentStep.value < 3) {
      // Basic validation for Step 1
      if (currentStep.value == 1) {
        if (nameController.text.length < 2) {
          Get.snackbar('Error', 'Please enter a valid name');
          return;
        }
        profile.update((val) {
          val?.fullName = nameController.text;
          val?.nationality = nationalityController.text;
        });
      }
      
      // Basic validation for Step 2
      if (currentStep.value == 2) {
        profile.update((val) {
          val?.weight = double.tryParse(weightController.text);
          val?.height = double.tryParse(heightController.text);
        });
      }

      currentStep.value++;
    } else {
      finishSetup();
    }
  }

  void prevStep() {
    if (currentStep.value > 1) {
      currentStep.value--;
    }
  }

  Future<void> finishSetup() async {
    profile.update((val) {
      val?.emergencyContactName = emergencyNameController.text;
      val?.emergencyContactRelation = emergencyRelationController.text;
      val?.emergencyContactMobile = emergencyMobileController.text;
      val?.homeCity = homeCityController.text;
      val?.homeState = homeStateController.text;
      val?.insuranceInfo = insuranceController.text;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.value.toJson()));
    await prefs.setBool('is_profile_complete', true);

    Get.offAllNamed(Routes.HOME);
  }

  void skipForNow() {
    Get.offAllNamed(Routes.HOME);
  }

  @override
  void onClose() {
    nameController.dispose();
    nationalityController.dispose();
    weightController.dispose();
    heightController.dispose();
    allergyController.dispose();
    emergencyNameController.dispose();
    emergencyRelationController.dispose();
    emergencyMobileController.dispose();
    homeCityController.dispose();
    homeStateController.dispose();
    insuranceController.dispose();
    super.onClose();
  }
}
