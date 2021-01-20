import 'package:flutter/material.dart';

AppBar header(
    {bool isAppTitle = false, String titleText, removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: !removeBackButton,
    title: Text(
      isAppTitle ? 'Roaster' : titleText,
      style: TextStyle(
          color: Colors.white,
          fontSize: isAppTitle ? 50 : 22,
          fontFamily: isAppTitle ? 'Signatra' : ""),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Colors.redAccent,
  );
}
