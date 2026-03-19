import 'package:flutter/material.dart';

/// Ayarlar ekranında tek satır: anahtar, başlık, açıklama, tür (switch / list / sayfa).
enum AppSettingType {
  switch_,
  listTile,
  subPage,
}

class AppSettingItem {
  const AppSettingItem({
    required this.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.settingType = AppSettingType.switch_,
    this.defaultValue = true,
  });

  final String key;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final AppSettingType settingType;
  final bool defaultValue;
}
