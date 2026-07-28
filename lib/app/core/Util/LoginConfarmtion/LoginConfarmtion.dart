import 'package:flutter/material.dart';

import '../../../../DataProvider/app_shared_preferences.dart';


class login{
  Future<bool> loginConfirm() async => await AppSharedPreferences().getBool(AppSharedPreferences.isLogin).then((value){
      return value;
    });
}