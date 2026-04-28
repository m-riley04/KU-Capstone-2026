/// Utility to map notifications to decoration info
class DecorationMapper {
  /// Extract team info from notification
  /// Returns {genre, team_name} or null if not a sports notification
  static Future<Map<String, String>?> mapNotificationToDecoration(
    String notificationTitle,
    String notificationCategory,
    String notificationInfo,
  ) async {
    final categoryLower = notificationCategory.toLowerCase().trim();
    final teamName =
        _extractTeamFromTitle(notificationTitle) ??
        _extractTeamFromTitle(notificationInfo);
    if (teamName == null) {
      return null;
    }

    final slug = _slugifyTeamName(teamName);
    if (slug.isEmpty) return null;

    // Men's College Basketball
    if (categoryLower.contains('ncaam') ||
        categoryLower.contains('mens college basketball') ||
        categoryLower.contains('mcb')) {
      return {
        'genre': 'mcb',
        'team_name': slug,
        'display_name': teamName,
      };
    }

    // NHL
    if (categoryLower.contains('nhl') || categoryLower.contains('hockey')) {
      return {
        'genre': 'nhl',
        'team_name': slug,
        'display_name': teamName,
      };
    }

    // Generic sources like ESPN: infer league from team name slug.
    if (_knownNhlTeamSlugs.contains(slug)) {
      return {
        'genre': 'nhl',
        'team_name': slug,
        'display_name': teamName,
      };
    }

    return {
      'genre': 'mcb',
      'team_name': slug,
      'display_name': teamName,
    };
  }

  /// Parse team name from notification title.
  /// Handles common matchup headlines and selects the team explicitly named
  /// by the headline pattern.
  static String? _extractTeamFromTitle(String title) {
    final titleLower = title.toLowerCase();

    String? indicatedTeam;

    // Headline formats where the first team is the one to decorate.
    const leadingTeamSeparators = [' defeats ', ' beat ', ' over '];
    for (final sep in leadingTeamSeparators) {
      if (titleLower.contains(sep)) {
        final parts = title.split(sep);
        if (parts.isNotEmpty) {
          indicatedTeam = parts.first.trim();
          break;
        }
      }
    }

    // Headline formats where the second team is the one to decorate.
    if (indicatedTeam == null) {
      for (final sep in [' at ', ' @ ']) {
        if (titleLower.contains(sep)) {
          final parts = title.split(sep);
          if (parts.length > 1) {
            indicatedTeam = parts.last.trim();
            break;
          }
        }
      }
    }

    // Fallback for generic matchup headlines.
    if (indicatedTeam == null) {
      for (final sep in [' vs ', ' vs. ']) {
        if (titleLower.contains(sep)) {
          final parts = title.split(sep);
          if (parts.isNotEmpty) {
            indicatedTeam = parts.first.trim();
            break;
          }
        }
      }
    }

    if (indicatedTeam == null || indicatedTeam.isEmpty) {
      // Fallback for titles that are just a team name plus metadata,
      // e.g. "Colorado Avalanche (1 games)".
      indicatedTeam = title;
    }

    final cleaned = _cleanupTeamCandidate(indicatedTeam);
    if (cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }

  static String _cleanupTeamCandidate(String candidate) {
    return candidate
        // Remove trailing parenthetical metadata like "(1 games)".
        .replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Convert team name to asset filename format (lowercase, underscores)
  static String _slugifyTeamName(String name) {
    final lowered = name.toLowerCase().trim();
    final slug = lowered
        .replaceAll(RegExp(r'[&]'), ' and ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return slug;
  }

  static const Set<String> _knownNhlTeamSlugs = {
    'anaheim_ducks',
    'boston_bruins',
    'buffalo_sabres',
    'calgary_flames',
    'carolina_hurricanes',
    'chicago_blackhawks',
    'colorado_avalanche',
    'columbus_blue_jackets',
    'dallas_stars',
    'detroit_red_wings',
    'edmonton_oilers',
    'florida_panthers',
    'los_angeles_kings',
    'minnesota_wild',
    'montreal_canadiens',
    'nashville_predators',
    'new_jersey_devils',
    'new_york_islanders',
    'new_york_rangers',
    'ottawa_senators',
    'philadelphia_flyers',
    'pittsburgh_penguins',
    'san_jose_sharks',
    'seattle_kraken',
    'st_louis_blues',
    'tampa_bay_lightning',
    'toronto_maple_leafs',
    'utah_hockey_club',
    'vancouver_canucks',
    'vegas_golden_knights',
    'washington_capitals',
    'winnipeg_jets',
  };
}
