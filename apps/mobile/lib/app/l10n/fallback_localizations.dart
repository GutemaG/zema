import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter ships built-in widget strings (dialog buttons, back tooltips,
/// text-selection menus) for `am` and `en`, but not for `om` or `ti`. These
/// delegates load the English built-in strings for those languages so
/// Material and Cupertino widgets keep working.
const Set<String> _fallbackLanguages = {'om', 'ti'};
const Locale _english = Locale('en');

/// Delegates to add after the `Global*Localizations` delegates.
const List<LocalizationsDelegate<Object>> fallbackLocalizationsDelegates = [
  _FallbackMaterialLocalizationsDelegate(),
  _FallbackCupertinoLocalizationsDelegate(),
  _FallbackWidgetsLocalizationsDelegate(),
];

class _FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _fallbackLanguages.contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_english);

  @override
  bool shouldReload(_FallbackMaterialLocalizationsDelegate old) => false;
}

class _FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _fallbackLanguages.contains(locale.languageCode);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_english);

  @override
  bool shouldReload(_FallbackCupertinoLocalizationsDelegate old) => false;
}

class _FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _fallbackLanguages.contains(locale.languageCode);

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(_english);

  @override
  bool shouldReload(_FallbackWidgetsLocalizationsDelegate old) => false;
}
