import { fetchEspnMensCollegeBasketballScoreboardData, fetchEspnMLBScoreboardData } from "../clients/ESPN-client";
import { setEventServices } from "../services/event-services";
import { getPreviousEspnScoreboardData, espnScoreboardHasChanged } from "../services/espn-services";
import { generateNotifications } from "../services/notification_services-services";

const ESPN_MCB_SCOREBOARD_INTEREST = "Men's College Basketball Scoreboard";
const ESPN_MLB_SCOREBOARD_INTEREST = 'MLB Scoreboard';

export const getEspnMensCollegeBasketballScoreboard: () => Promise<void> = async () => {
    try {
        const currentScoreboardData = await fetchEspnMensCollegeBasketballScoreboardData();
        const oldScoreboardData = await getPreviousEspnScoreboardData(ESPN_MCB_SCOREBOARD_INTEREST);

        if (!espnScoreboardHasChanged(currentScoreboardData, oldScoreboardData)) {
            console.log('ESPN scoreboard data has not changed since the last fetch. Skipping notification.');
            return;
        }

        await setEventServices(currentScoreboardData, ESPN_MCB_SCOREBOARD_INTEREST);
        await generateNotifications(ESPN_MCB_SCOREBOARD_INTEREST);
        console.log('ESPN scoreboard data changed. Event saved and notifications generated.');
    } catch (error) {
        console.error('Error fetching ESPN scoreboard data:', error);
        throw error;
    }
}

export const getEspnMLBScoreboard: () => Promise<void> = async () => {
    try {
        const currentScoreboardData = await fetchEspnMLBScoreboardData();
        const oldScoreboardData = await getPreviousEspnScoreboardData(ESPN_MLB_SCOREBOARD_INTEREST);

        if (!espnScoreboardHasChanged(currentScoreboardData, oldScoreboardData)) {
            console.log('ESPN scoreboard data has not changed since the last fetch. Skipping notification.');
            return;
        }

        await setEventServices(currentScoreboardData, ESPN_MLB_SCOREBOARD_INTEREST);
        await generateNotifications(ESPN_MLB_SCOREBOARD_INTEREST);
        console.log('ESPN scoreboard data changed. Event saved and notifications generated.');
    } catch (error) {
        console.error('Error fetching ESPN scoreboard data:', error);
        throw error;
    }
}