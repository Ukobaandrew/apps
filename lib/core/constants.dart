// lib/core/constants.dart

class AppConstants {
  static const String appName = 'TaskWin';

  // Old fees (kept for backward compatibility – not used in new distribution)
  static const double platformFee = 0.15; // 15%
  static const double hostBonus = 0.05; // 5% for host

  // New prize distribution (80% winner, 10% host, 10% platform)
  static const double winnerShare = 0.80;
  static const double hostShare = 0.05;
  static const double platformShare = 0.15;
  static const String platformUserId = 'UcejfoG3TUUZMOWbPmmReVqResk1';

  static const List<String> categories = [
    'Trending',
    'Fun',
    'Creative',
    'Crazy',
    'Skill',
    'Sports',
  ];

  static const List<String> entryTypes = [
    'Video',
    'Photo',
    'Audio',
    'Text',
  ];

  static const int otpLength = 6;
  static const int minParticipantsDefault = 2;
  static const int maxParticipantsDefault = 50;
  static const int votingDurationDefault = 24; // hours
}
