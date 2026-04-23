import { eventData } from "../models/notifications";

const ESPN_MCB_SCOREBOARD_URL =
    'https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/scoreboard';

const ESPN_MLB_SCOREBOARD_URL =
    'https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard';

const ESPN_NBA_SCOREBOARD_URL =
    'https://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard';

const ESPN_NFL_SCOREBOARD_URL =
    'https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard';

const ESPN_NHL_SCOREBOARD_URL =
    'https://site.api.espn.com/apis/site/v2/sports/hockey/nhl/scoreboard';

interface EspnTeam {
    displayName?: string;
    shortDisplayName?: string;
    abbreviation?: string;
    name?: string;
    location?: string;
    nickname?: string;
}

interface EspnCompetitor {
    homeAway?: 'home' | 'away';
    score?: string;
    team?: EspnTeam;
}

interface EspnCompetition {
    competitors?: EspnCompetitor[];
    status?: {
        type?: {
            shortDetail?: string;
            description?: string;
        };
    };
}

export interface EspnScoreboardEvent {
    competitions?: EspnCompetition[];
}

export interface EspnSportConfig {
    url: string;
    media: string;
    headlinePrefix: string;
    noGamesMessage: string;
    seemore: string;
}

const summarizeGames = (events: EspnScoreboardEvent[], noGamesMessage: string): string => {
    if (!events || events.length === 0) {
        return noGamesMessage;
    }

    const summaries = events.slice(0, 10).map((event: EspnScoreboardEvent) => {
        const competition = event?.competitions?.[0];
        const competitors = competition?.competitors ?? [];
        const home = competitors.find((c: EspnCompetitor) => c?.homeAway === 'home');
        const away = competitors.find((c: EspnCompetitor) => c?.homeAway === 'away');
        const status = competition?.status?.type?.shortDetail ?? competition?.status?.type?.description ?? 'Status unavailable';

        const awayName = away?.team?.abbreviation ?? away?.team?.displayName ?? 'Away';
        const homeName = home?.team?.abbreviation ?? home?.team?.displayName ?? 'Home';
        const awayScore = away?.score ?? '-';
        const homeScore = home?.score ?? '-';

        return `${awayName} ${awayScore} - ${homeName} ${homeScore} (${status})`;
    });

    return summaries.join(' | ');
}

export const fetchEspnScoreboardEvents = async (url: string): Promise<EspnScoreboardEvent[]> => {
    const response = await fetch(url);

    if (!response.ok) {
        throw new Error(`Error fetching ESPN scoreboard data: ${response.statusText}`);
    }

    const data: unknown = await response.json();
    const events = (data as { events?: EspnScoreboardEvent[] } | null)?.events;
    return Array.isArray(events) ? events : [];
}

export const createEspnScoreboardEventData = (
    sportConfig: EspnSportConfig,
    events: EspnScoreboardEvent[],
    headlineOverride?: string,
): eventData => {
    const headline = headlineOverride ?? `${sportConfig.headlinePrefix} (${events.length} games)`;

    return {
        timestamp: new Date(),
        media: sportConfig.media,
        headline,
        info: summarizeGames(events, sportConfig.noGamesMessage),
        from_source: 'ESPN',
        seemore: sportConfig.seemore,
    };
}

const fetchEspnScoreboardData = async (sportConfig: EspnSportConfig): Promise<eventData> => {
    const events = await fetchEspnScoreboardEvents(sportConfig.url);
    return createEspnScoreboardEventData(sportConfig, events);
}

export const fetchEspnMensCollegeBasketballScoreboardData = async () : Promise<eventData> => {
    return fetchEspnScoreboardData({
        url: ESPN_MCB_SCOREBOARD_URL,
        media: 'https://a.espncdn.com/redesign/assets/img/icons/ESPN-icon-basketball.png',
        headlinePrefix: 'NCAA Mens College Basketball Scoreboard',
        noGamesMessage: 'No games currently on the men\'s college basketball scoreboard.',
        seemore: ESPN_MCB_SCOREBOARD_URL,
    });
}

export const fetchEspnMLBScoreboardData = async () : Promise<eventData> => {
    return fetchEspnScoreboardData({
        url: ESPN_MLB_SCOREBOARD_URL,
        media: 'https://a.espncdn.com/i/teamlogos/leagues/500/mlb.png',
        headlinePrefix: 'MLB Scoreboard',
        noGamesMessage: 'No games currently on the MLB scoreboard.',
        seemore: ESPN_MLB_SCOREBOARD_URL,
    });
}

export const fetchEspnNBAScoreboardData = async (): Promise<eventData> => {
    return fetchEspnScoreboardData({
        url: ESPN_NBA_SCOREBOARD_URL,
        media: 'https://a.espncdn.com/i/teamlogos/leagues/500/nba.png',
        headlinePrefix: 'NBA Scoreboard',
        noGamesMessage: 'No games currently on the NBA scoreboard.',
        seemore: ESPN_NBA_SCOREBOARD_URL,
    });
}

export const fetchEspnNFLScoreboardData = async (): Promise<eventData> => {
    return fetchEspnScoreboardData({
        url: ESPN_NFL_SCOREBOARD_URL,
        media: 'https://a.espncdn.com/i/teamlogos/leagues/500/nfl.png',
        headlinePrefix: 'NFL Scoreboard',
        noGamesMessage: 'No games currently on the NFL scoreboard.',
        seemore: ESPN_NFL_SCOREBOARD_URL,
    });
}

export const fetchEspnNHLScoreboardData = async (): Promise<eventData> => {
    return fetchEspnScoreboardData({
        url: ESPN_NHL_SCOREBOARD_URL,
        media: 'https://a.espncdn.com/i/teamlogos/leagues/500/nhl.png',
        headlinePrefix: 'NHL Scoreboard',
        noGamesMessage: 'No games currently on the NHL scoreboard.',
        seemore: ESPN_NHL_SCOREBOARD_URL,
    });
}

export const ESPN_SPORT_CONFIGS = {
    mensCollegeBasketball: {
        url: ESPN_MCB_SCOREBOARD_URL,
        media: 'https://a.espncdn.com/redesign/assets/img/icons/ESPN-icon-basketball.png',
        headlinePrefix: 'NCAA Mens College Basketball Scoreboard',
        noGamesMessage: 'No games currently on the men\'s college basketball scoreboard.',
        seemore: ESPN_MCB_SCOREBOARD_URL,
    } as EspnSportConfig,
    mlb: {
        url: ESPN_MLB_SCOREBOARD_URL,
        media: 'https://a.espncdn.com/i/teamlogos/leagues/500/mlb.png',
        headlinePrefix: 'MLB Scoreboard',
        noGamesMessage: 'No games currently on the MLB scoreboard.',
        seemore: ESPN_MLB_SCOREBOARD_URL,
    } as EspnSportConfig,
    nba: {
        url: ESPN_NBA_SCOREBOARD_URL,
        media: 'https://a.espncdn.com/i/teamlogos/leagues/500/nba.png',
        headlinePrefix: 'NBA Scoreboard',
        noGamesMessage: 'No games currently on the NBA scoreboard.',
        seemore: ESPN_NBA_SCOREBOARD_URL,
    } as EspnSportConfig,
    nfl: {
        url: ESPN_NFL_SCOREBOARD_URL,
        media: 'https://a.espncdn.com/i/teamlogos/leagues/500/nfl.png',
        headlinePrefix: 'NFL Scoreboard',
        noGamesMessage: 'No games currently on the NFL scoreboard.',
        seemore: ESPN_NFL_SCOREBOARD_URL,
    } as EspnSportConfig,
    nhl: {
        url: ESPN_NHL_SCOREBOARD_URL,
        media: 'https://a.espncdn.com/i/teamlogos/leagues/500/nhl.png',
        headlinePrefix: 'NHL Scoreboard',
        noGamesMessage: 'No games currently on the NHL scoreboard.',
        seemore: ESPN_NHL_SCOREBOARD_URL,
    } as EspnSportConfig,
};
