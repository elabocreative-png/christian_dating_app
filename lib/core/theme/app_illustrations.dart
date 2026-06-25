/// Asset paths for larger SVG illustrations in [assets/illustrations/].
abstract final class AppIllustrations {
  static const String _dir = 'assets/illustrations';

  static const String noMessagesConnections =
      '$_dir/no_messages_connections_svg.svg';
  static const String noLikesYet = '$_dir/no_likes_yet_svg.svg';
  static const String noMoreUsers = '$_dir/no_more_users.svg';
  static const String femaleSilhouette = '$_dir/female_silluet.svg';
  static const String maleSilhouette = '$_dir/male_silluet.svg';
  static const String avatarFemale = '$_dir/Avatar_female.svg';
  static const String avatarMale = '$_dir/Avatar_male.svg';
  static const String faithDeclaration = '$_dir/faith_declaration.svg';
  static const String supportEnvelope = '$_dir/support_envelope.svg';

  static String pathFor(String fileName) {
    final name = fileName.endsWith('.svg') ? fileName : '$fileName.svg';
    return '$_dir/$name';
  }
}
