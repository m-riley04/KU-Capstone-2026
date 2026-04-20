import { eventData } from "../models/notifications";

const ESPN_MCB_SCOREBOARD_URL =
    'https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/scoreboard';

const ESPN_MLB_SCOREBOARD_URL =
    'https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard';

const summarizeGames = (events: any[]): string => {
    if (!events || events.length === 0) {
        return 'No games currently on the mens college basketball scoreboard.';
    }

    const summaries = events.slice(0, 10).map((event: any) => {
        const competition = event?.competitions?.[0];
        const competitors = competition?.competitors ?? [];
        const home = competitors.find((c: any) => c?.homeAway === 'home');
        const away = competitors.find((c: any) => c?.homeAway === 'away');
        const status = competition?.status?.type?.shortDetail ?? competition?.status?.type?.description ?? 'Status unavailable';

        const awayName = away?.team?.abbreviation ?? away?.team?.displayName ?? 'Away';
        const homeName = home?.team?.abbreviation ?? home?.team?.displayName ?? 'Home';
        const awayScore = away?.score ?? '-';
        const homeScore = home?.score ?? '-';

        return `${awayName} ${awayScore} - ${homeName} ${homeScore} (${status})`;
    });

    return summaries.join(' | ');
}

export const fetchEspnMensCollegeBasketballScoreboardData = async () : Promise<eventData> => {
    const response = await fetch(ESPN_MCB_SCOREBOARD_URL);

    if (!response.ok) {
        throw new Error(`Error fetching ESPN scoreboard data: ${response.statusText}`);
    }

    const data = await response.json();
    const events = Array.isArray(data?.events) ? data.events : [];

    return {
        timestamp: new Date(),
        media: 'https://a.espncdn.com/redesign/assets/img/icons/ESPN-icon-basketball.png',
        headline: `NCAA Mens College Basketball Scoreboard (${events.length} games)`,
        info: summarizeGames(events),
        from_source: 'ESPN',
        seemore: '' //'https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/scoreboard'
    }
}

export const fetchEspnMLBScoreboardData = async () : Promise<eventData> => {
    const response = await fetch(ESPN_MLB_SCOREBOARD_URL);

    if (!response.ok) {
        throw new Error(`Error fetching ESPN scoreboard data: ${response.statusText}`);
    }

    const data = await response.json();
    const events = Array.isArray(data?.events) ? data.events : [];

    return {
        timestamp: new Date(),
        media: 'https://a.espncdn.com/i/teamlogos/leagues/500/mlb.png',
        headline: `MLB Scoreboard (${events.length} games)`,
        info: summarizeGames(events),
        from_source: 'ESPN',
        seemore: '' //https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/scoreboard'
    }
}
