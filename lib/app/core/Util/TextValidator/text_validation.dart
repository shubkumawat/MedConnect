
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TxtValidation{


  static normalTextField(TextEditingController controller){
    if(controller.text.toString().trim().isEmpty || controller.text.toString().trim() == null)
      return false;
    return true;
  }

  static validateMobileTextField(TextEditingController controller){
    if(controller.text.toString().trim().isEmpty || controller.text.toString().trim().length < 10)
      return false;
    return true;
  }

  static validatePinTextField(TextEditingController controller){
    if(controller.text.toString().trim().isEmpty || controller.text.toString().trim().length < 4)
      return false;
    return true;
  }
  static validatePasswordTextField(TextEditingController controller){
    if(controller.text.toString().trim().isEmpty || controller.text.toString().trim().length < 8)
      return false;
    return true;
  }
  static otpVeTextField(TextEditingController controller){
    if(controller.text.toString().trim().isEmpty || controller.text.toString().trim().length != 6)
      return false;
    return true;
  }

  static validateEmailTextField(TextEditingController controller){
    if(controller.text.toString().trim().isEmpty || controller.text.toString().trim() == null)
      return false;
    RegExp regex = new RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!regex.hasMatch(controller.text.toString().trim()))
      return false;
    return true;
  }

}