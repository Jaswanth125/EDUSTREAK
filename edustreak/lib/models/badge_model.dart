class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String icon; // emoji or icon name
  final int xpReward;
  final String category; // attendance, streak, assignment, challenge

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.xpReward = 0,
    required this.category,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      xpReward: map['xpReward'] ?? 0,
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'xpReward': xpReward,
      'category': category,
    };
  }

  static List<BadgeModel> getDefaultBadges() {
    return [
      // Attendance Badges
      BadgeModel(
        id: 'attendance_hero',
        name: 'Attendance Hero',
        description: '100% attendance for a month',
        icon: '🏆',
        xpReward: 50,
        category: 'attendance',
      ),
      BadgeModel(
        id: 'consistency_star',
        name: 'Consistency Star',
        description: '90%+ attendance for a month',
        icon: '⭐',
        xpReward: 30,
        category: 'attendance',
      ),
      BadgeModel(
        id: 'perfect_attendance',
        name: 'Perfect Attendance',
        description: '100% attendance for a month',
        icon: '💯',
        xpReward: 300,
        category: 'attendance',
      ),
      BadgeModel(
        id: 'early_bird',
        name: 'Early Bird',
        description: 'Never late for 20 days',
        icon: '🐦',
        xpReward: 150,
        category: 'attendance',
      ),
      // Streak Badges
      BadgeModel(
        id: 'consistency_king',
        name: 'Consistency King/Queen',
        description: 'Maintain a 7-day streak',
        icon: '👑',
        xpReward: 150,
        category: 'streak',
      ),
      BadgeModel(
        id: 'streak_master',
        name: 'Streak Master',
        description: 'Maintain a 30-day streak',
        icon: '🔥',
        xpReward: 500,
        category: 'streak',
      ),
      BadgeModel(
        id: 'unbreakable',
        name: 'Unbreakable',
        description: 'Maintain a 100-day streak',
        icon: '💪',
        xpReward: 1000,
        category: 'streak',
      ),
      // Assignment Badges
      BadgeModel(
        id: 'assignment_ace',
        name: 'Assignment Ace',
        description: 'Submit 5 tasks on time',
        icon: '⭐',
        xpReward: 100,
        category: 'assignment',
      ),
      BadgeModel(
        id: 'homework_hero',
        name: 'Homework Hero',
        description: 'Submit 10 assignments on time',
        icon: '📚',
        xpReward: 250,
        category: 'assignment',
      ),
      BadgeModel(
        id: 'top_performer',
        name: 'Top Performer',
        description: 'Get 90+ marks in 5 assignments',
        icon: '🏅',
        xpReward: 400,
        category: 'assignment',
      ),
      BadgeModel(
        id: 'perfectionist',
        name: 'Perfectionist',
        description: 'Get 100 marks in any assignment',
        icon: '💎',
        xpReward: 500,
        category: 'assignment',
      ),
      // Challenge Badges
      BadgeModel(
        id: 'week_warrior',
        name: 'Week Warrior',
        description: 'Complete all weekly challenges',
        icon: '⚔️',
        xpReward: 300,
        category: 'challenge',
      ),
      BadgeModel(
        id: 'challenge_champion',
        name: 'Challenge Champion',
        description: 'Complete 10 challenges',
        icon: '🏆',
        xpReward: 400,
        category: 'challenge',
      ),
      // Level Badges
      BadgeModel(
        id: 'bronze_warrior',
        name: 'Bronze Warrior',
        description: 'Reach Level 5',
        icon: '🥉',
        xpReward: 100,
        category: 'level',
      ),
      BadgeModel(
        id: 'silver_champion',
        name: 'Silver Champion',
        description: 'Reach Level 10',
        icon: '🥈',
        xpReward: 250,
        category: 'level',
      ),
      BadgeModel(
        id: 'gold_legend',
        name: 'Gold Legend',
        description: 'Reach Level 15',
        icon: '🥇',
        xpReward: 500,
        category: 'level',
      ),
      BadgeModel(
        id: 'platinum_master',
        name: 'Platinum Master',
        description: 'Reach Level 20',
        icon: '💎',
        xpReward: 750,
        category: 'level',
      ),
      BadgeModel(
        id: 'diamond_elite',
        name: 'Diamond Elite',
        description: 'Reach Level 25',
        icon: '✨',
        xpReward: 1000,
        category: 'level',
      ),
      // Additional Achievement Badges
      BadgeModel(
        id: 'first_submission',
        name: 'First Steps',
        description: 'Submit your first assignment',
        icon: '🌱',
        xpReward: 50,
        category: 'assignment',
      ),
      BadgeModel(
        id: 'speed_demon',
        name: 'Speed Demon',
        description: 'Submit 3 assignments early',
        icon: '⚡',
        xpReward: 200,
        category: 'assignment',
      ),
      BadgeModel(
        id: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Send 50 messages',
        icon: '🦋',
        xpReward: 100,
        category: 'social',
      ),
      BadgeModel(
        id: 'explorer',
        name: 'Explorer',
        description: 'Purchase your first avatar',
        icon: '🗺️',
        xpReward: 75,
        category: 'store',
      ),
      BadgeModel(
        id: 'collector',
        name: 'Collector',
        description: 'Purchase 5 avatars',
        icon: '🎨',
        xpReward: 300,
        category: 'store',
      ),
      BadgeModel(
        id: 'champion_week',
        name: 'Week Champion',
        description: 'Complete all challenges in a week',
        icon: '🏅',
        xpReward: 400,
        category: 'challenge',
      ),
      BadgeModel(
        id: 'knowledge_seeker',
        name: 'Knowledge Seeker',
        description: 'Score 80+ in 10 assignments',
        icon: '📖',
        xpReward: 500,
        category: 'assignment',
      ),
      BadgeModel(
        id: 'rising_star',
        name: 'Rising Star',
        description: 'Reach top 3 in leaderboard',
        icon: '⭐',
        xpReward: 600,
        category: 'leaderboard',
      ),
      BadgeModel(
        id: 'legend',
        name: 'Legend',
        description: 'Reach #1 in leaderboard',
        icon: '👑',
        xpReward: 1000,
        category: 'leaderboard',
      ),
      BadgeModel(
        id: 'dedicated',
        name: 'Dedicated Learner',
        description: 'Maintain 20-day streak',
        icon: '🎓',
        xpReward: 400,
        category: 'streak',
      ),
    ];
  }
}

