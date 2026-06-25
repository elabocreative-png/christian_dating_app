/// Asset paths for Figma-exported SVGs in [assets/icons/].
abstract final class AppIcons {
  static const String _dir = 'assets/icons';

  static const String cardsSolid = '$_dir/cards_icon_solid.svg';
  static const String cardsOutline = '$_dir/cards_icon_outline.svg';
  static const String heartSolid = '$_dir/heart_icon_solid.svg';
  static const String heartOutline = '$_dir/heart_icon_outline.svg';
  static const String chatsSolid = '$_dir/chats_icon_solid.svg';
  static const String chatsOutline = '$_dir/chats_icon_outline.svg';
  static const String introIconOutline = '$_dir/intro_icon_outline.svg';
  static const String introIconSolid = '$_dir/intro_icon_solid.svg';
  static const String profileSolid = '$_dir/profile_icon_solid.svg';
  static const String profileOutline = '$_dir/profile_icon_outline.svg';

  static const String appLogoSolid = '$_dir/app_logo_solid.svg';
  static const String premium = '$_dir/premium.svg';
  static const String verifiedSolid = '$_dir/verified_icon_solid.svg';
  static const String bookmarkOutline = '$_dir/bookmark_icon_outline.svg';
  static const String filterSolid = '$_dir/filter_icon_solid.svg';
  static const String closeSolid = '$_dir/close_icon_solid.svg';
  static const String undoSolid = '$_dir/undo_icon_solid.svg';
  static const String searchChat = '$_dir/search_chat_svg.svg';
  static const String settings = '$_dir/setting_icon.svg';
  static const String edit = '$_dir/edit_icon.svg';
  static const String mapPointer = '$_dir/Map_pointer.svg';
  static const String locationIcon = '$_dir/location_icon.svg';
  static const String ellipsis = '$_dir/ellipsis_icon.svg';
  static const String quoteMark = '$_dir/quote_mark_icon.svg';
  static const String fingerTap = '$_dir/finger-tap.svg';
  static const String swipeGesture = '$_dir/swipe_gesture.svg';
  static const String handWaveSolid = '$_dir/hand_wave_solid.svg';
  static const String send = '$_dir/send.svg';
  static const String reply = '$_dir/reply_icon.svg';

  static String pathFor(String fileName) {
    final name = fileName.endsWith('.svg') ? fileName : '$fileName.svg';
    return '$_dir/$name';
  }
}
