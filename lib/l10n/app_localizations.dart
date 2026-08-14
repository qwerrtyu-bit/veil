import 'package:flutter/material.dart';
import 'app_ru.dart';
import 'app_en.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  String get appName => _getString('appName', AppRu.appName, AppEn.appName);
  String get tagline => _getString('tagline', AppRu.tagline, AppEn.tagline);
  String get chats => _getString('chats', AppRu.chats, AppEn.chats);
  String get noChats => _getString('noChats', AppRu.noChats, AppEn.noChats);
  String get search => _getString('search', AppRu.search, AppEn.search);
  String get settings => _getString('settings', AppRu.settings, AppEn.settings);
  String get profile => _getString('profile', AppRu.profile, AppEn.profile);
  String get addContact => _getString('addContact', AppRu.addContact, AppEn.addContact);
  String get createGroup => _getString('createGroup', AppRu.createGroup, AppEn.createGroup);
  String get channels => _getString('channels', AppRu.channels, AppEn.channels);
  String get plugins => _getString('plugins', AppRu.plugins, AppEn.plugins);
  String get notes => _getString('notes', AppRu.notes, AppEn.notes);
  String get stories => _getString('stories', AppRu.stories, AppEn.stories);
  String get access => _getString('access', AppRu.access, AppEn.access);
  String get docVerify => _getString('docVerify', AppRu.docVerify, AppEn.docVerify);
  String get faq => _getString('faq', AppRu.faq, AppEn.faq);
  String get sync => _getString('sync', AppRu.sync, AppEn.sync);
  String get syncing => _getString('syncing', AppRu.syncing, AppEn.syncing);
  String get message => _getString('message', AppRu.message, AppEn.message);
  String get send => _getString('send', AppRu.send, AppEn.send);
  String get delete => _getString('delete', AppRu.delete, AppEn.delete);
  String get cancel => _getString('cancel', AppRu.cancel, AppEn.cancel);
  String get deleteMessage => _getString('deleteMessage', AppRu.deleteMessage, AppEn.deleteMessage);
  String get deleteMessageDesc => _getString('deleteMessageDesc', AppRu.deleteMessageDesc, AppEn.deleteMessageDesc);
  String get reply => _getString('reply', AppRu.reply, AppEn.reply);
  String get selfDestruct => _getString('selfDestruct', AppRu.selfDestruct, AppEn.selfDestruct);
  String get stickers => _getString('stickers', AppRu.stickers, AppEn.stickers);
  String get voice => _getString('voice', AppRu.voice, AppEn.voice);
  String get videoMsg => _getString('videoMsg', AppRu.videoMsg, AppEn.videoMsg);
  String get photo => _getString('photo', AppRu.photo, AppEn.photo);
  String get video => _getString('video', AppRu.video, AppEn.video);
  String get file => _getString('file', AppRu.file, AppEn.file);
  String get enterPassword => _getString('enterPassword', AppRu.enterPassword, AppEn.enterPassword);
  String get enterCode => _getString('enterCode', AppRu.enterCode, AppEn.enterCode);
  String get login => _getString('login', AppRu.login, AppEn.login);
  String get loginPin => _getString('loginPin', AppRu.loginPin, AppEn.loginPin);
  String get loginPassword => _getString('loginPassword', AppRu.loginPassword, AppEn.loginPassword);
  String get wrongPassword => _getString('wrongPassword', AppRu.wrongPassword, AppEn.wrongPassword);
  String get tryLater => _getString('tryLater', AppRu.tryLater, AppEn.tryLater);
  String get setupPin => _getString('setupPin', AppRu.setupPin, AppEn.setupPin);
  String get resetIdentity => _getString('resetIdentity', AppRu.resetIdentity, AppEn.resetIdentity);
  String get subscribe => _getString('subscribe', AppRu.subscribe, AppEn.subscribe);
  String get unsubscribe => _getString('unsubscribe', AppRu.unsubscribe, AppEn.unsubscribe);
  String get newPost => _getString('newPost', AppRu.newPost, AppEn.newPost);
  String get installPlugin => _getString('installPlugin', AppRu.installPlugin, AppEn.installPlugin);
  String get scanQR => _getString('scanQR', AppRu.scanQR, AppEn.scanQR);
  String get enterVerifyPassword => _getString('enterVerifyPassword', AppRu.enterVerifyPassword, AppEn.enterVerifyPassword);
  String get docOriginal => _getString('docOriginal', AppRu.docOriginal, AppEn.docOriginal);
  String get docFake => _getString('docFake', AppRu.docFake, AppEn.docFake);
  String get docNoScan => _getString('docNoScan', AppRu.docNoScan, AppEn.docNoScan);
  String get docWrongPassword => _getString('docWrongPassword', AppRu.docWrongPassword, AppEn.docWrongPassword);

  // Подписки
  String get subscription => _getString('subscription', AppRu.subscription, AppEn.subscription);
  String get currentPlan => _getString('currentPlan', AppRu.currentPlan, AppEn.currentPlan);
  String get upgrade => _getString('upgrade', AppRu.upgrade, AppEn.upgrade);
  String get choosePlan => _getString('choosePlan', AppRu.choosePlan, AppEn.choosePlan);
  String get free => _getString('free', AppRu.free, AppEn.free);
  String get plus => _getString('plus', AppRu.plus, AppEn.plus);
  String get dev => _getString('dev', AppRu.dev, AppEn.dev);
  String get pro => _getString('pro', AppRu.pro, AppEn.pro);
  String get freeDesc => _getString('freeDesc', AppRu.freeDesc, AppEn.freeDesc);
  String get plusDesc => _getString('plusDesc', AppRu.plusDesc, AppEn.plusDesc);
  String get devDesc => _getString('devDesc', AppRu.devDesc, AppEn.devDesc);
  String get proDesc => _getString('proDesc', AppRu.proDesc, AppEn.proDesc);

  String _getString(String key, String ru, String en) {
    switch (locale.languageCode) {
      case 'ru':
        return ru;
      default:
        return en;
    }
  }

  String syncDone(int count) {
    return _getString('syncDone', AppRu.syncDone.replaceFirst('{}', count.toString()), AppEn.syncDone.replaceFirst('{}', count.toString()));
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ru', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}