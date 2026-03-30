import { fetchEspnMensCollegeBasketballScoreboardData } from "../clients/ESPN-client";
import { setEventServices } from "../services/event-services";
import { getPreviousEspnScoreboardData, espnScoreboardHasChanged } from "../services/espn-services";
import { generateNotifications } from "../services/notification_services-services";

const ESPN_SCOREBOARD_INTEREST = 'espn_mens_college_basketball_scoreboard';

export const getEspnMensCollegeBasketballScoreboard: () => Promise<void> = async () => {
    try {
        const currentScoreboardData = await fetchEspnMensCollegeBasketballScoreboardData();
        const oldScoreboardData = await getPreviousEspnScoreboardData();

        if (!espnScoreboardHasChanged(currentScoreboardData, oldScoreboardData)) {
            console.log('ESPN scoreboard data has not changed since the last fetch. Skipping notification.');
            return;
        }

        await setEventServices(currentScoreboardData, ESPN_SCOREBOARD_INTEREST);
        await generateNotifications(ESPN_SCOREBOARD_INTEREST);
        console.log('ESPN scoreboard data changed. Event saved and notifications generated.');
    } catch (error) {
        console.error('Error fetching ESPN scoreboard data:', error);
        throw error;
    }
}