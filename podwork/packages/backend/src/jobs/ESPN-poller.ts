import { ESPN_SPORT_CONFIGS, createEspnScoreboardEventData, EspnSportConfig, fetchEspnScoreboardEvents } from "../clients/ESPN-client";
import { setEventServices } from "../services/event-services";
import {
    espnScoreboardHasChanged,
    filterScoreboardEventsByTeamInterest,
    getInterestNamesByCategory,
    getPreviousEspnScoreboardData,
} from "../services/espn-services";
import { generateNotifications } from "../services/notification_services-services";

const ESPN_MCB_SCOREBOARD_INTEREST = "Men's College Basketball Scoreboard";
const ESPN_MLB_SCOREBOARD_INTEREST = 'MLB Scoreboard';
const ESPN_CATEGORY_MCB = "Men's College Basketball";
const ESPN_CATEGORY_MLB = 'MLB';
const ESPN_CATEGORY_NBA = 'NBA';
const ESPN_CATEGORY_NFL = 'NFL';
const ESPN_CATEGORY_NHL = 'NHL';

interface EspnPollerConfig {
    category: string;
    sport: EspnSportConfig;
    scoreboardInterest?: string;
}

const maybePublishEspnInterest = async (
    interestName: string,
    currentScoreboardData: ReturnType<typeof createEspnScoreboardEventData>,
): Promise<boolean> => {
    const oldScoreboardData = await getPreviousEspnScoreboardData(interestName);

    if (!espnScoreboardHasChanged(currentScoreboardData, oldScoreboardData)) {
        return false;
    }

    await setEventServices(currentScoreboardData, interestName);
    await generateNotifications(interestName);
    return true;
}

const processEspnSport = async (config: EspnPollerConfig): Promise<void> => {
    const events = await fetchEspnScoreboardEvents(config.sport.url);

    if (config.scoreboardInterest) {
        const scoreboardData = createEspnScoreboardEventData(config.sport, events);
        const scoreboardUpdated = await maybePublishEspnInterest(config.scoreboardInterest, scoreboardData);

        if (scoreboardUpdated) {
            console.log(`${config.scoreboardInterest} data changed. Event saved and notifications generated.`);
        } else {
            console.log(`${config.scoreboardInterest} data has not changed since the last fetch. Skipping notification.`);
        }
    }

    const teamInterests = (await getInterestNamesByCategory(config.category))
        .filter((interestName) => interestName !== config.scoreboardInterest);

    if (teamInterests.length === 0) {
        return;
    }

    const gamesByInterest = filterScoreboardEventsByTeamInterest(events, teamInterests);

    for (const [interestName, matchingGames] of Object.entries(gamesByInterest)) {
        const teamScoreboardData = createEspnScoreboardEventData(
            config.sport,
            matchingGames,
            `${interestName} (${matchingGames.length} games)`,
        );

        const wasUpdated = await maybePublishEspnInterest(interestName, teamScoreboardData);
        if (wasUpdated) {
            console.log(`${interestName} ESPN data changed. Event saved and notifications generated.`);
        }
    }
}

export const getEspnMensCollegeBasketballScoreboard: () => Promise<void> = async () => {
    try {
        await processEspnSport({
            category: ESPN_CATEGORY_MCB,
            sport: ESPN_SPORT_CONFIGS.mensCollegeBasketball,
            scoreboardInterest: ESPN_MCB_SCOREBOARD_INTEREST,
        });
    } catch (error) {
        console.error('Error fetching ESPN scoreboard data:', error);
        throw error;
    }
}

export const getEspnMLBScoreboard: () => Promise<void> = async () => {
    try {
        await processEspnSport({
            category: ESPN_CATEGORY_MLB,
            sport: ESPN_SPORT_CONFIGS.mlb,
            scoreboardInterest: ESPN_MLB_SCOREBOARD_INTEREST,
        });
    } catch (error) {
        console.error('Error fetching ESPN scoreboard data:', error);
        throw error;
    }
}

export const getEspnNBAScoreboard: () => Promise<void> = async () => {
    try {
        await processEspnSport({
            category: ESPN_CATEGORY_NBA,
            sport: ESPN_SPORT_CONFIGS.nba,
        });
    } catch (error) {
        console.error('Error fetching ESPN scoreboard data:', error);
        throw error;
    }
}

export const getEspnNFLScoreboard: () => Promise<void> = async () => {
    try {
        await processEspnSport({
            category: ESPN_CATEGORY_NFL,
            sport: ESPN_SPORT_CONFIGS.nfl,
        });
    } catch (error) {
        console.error('Error fetching ESPN scoreboard data:', error);
        throw error;
    }
}

export const getEspnNHLScoreboard: () => Promise<void> = async () => {
    try {
        await processEspnSport({
            category: ESPN_CATEGORY_NHL,
            sport: ESPN_SPORT_CONFIGS.nhl,
        });
    } catch (error) {
        console.error('Error fetching ESPN scoreboard data:', error);
        throw error;
    }
}