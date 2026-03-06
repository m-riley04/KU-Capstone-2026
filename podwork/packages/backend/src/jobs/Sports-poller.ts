import { fetchCollegeBaskballNews, fetchNFLNews } from "../clients/Sports-client";
import { setEventServices } from "../services/event-services";
import { getPreviousSportsData } from "../services/sports-services";
import { generateNotifications } from "../services/notification_services-services";

export const getSportsNews = async (sportType: 'cbb' | 'nfl'): Promise<void> => {
    try {
        let currentSportsData;
        let notificationType: 'cbb' | 'nfl';
        
        if (sportType === 'cbb') {
            currentSportsData = await fetchCollegeBaskballNews();
            notificationType = 'cbb';
        } else if (sportType === 'nfl') {
            currentSportsData = await fetchNFLNews();
            notificationType = 'nfl';
        } else {
            throw new Error(`Unknown sport type: ${sportType}`);
        }
        
        const oldSportsData = await getPreviousSportsData(sportType);
        
        if (!oldSportsData) {
            console.log(`No previous ${sportType} data found. Adding current data and generating notification.`);
            await setEventServices(currentSportsData);
            await generateNotifications(notificationType);
        } else if (currentSportsData && oldSportsData && currentSportsData.timestamp === oldSportsData.timestamp) {
            console.log(`${sportType} data has not changed since the last fetch. Skipping notification.`);
        } else {
            console.log(`New ${sportType} data found. Updating and generating notification.`);
            await setEventServices(currentSportsData);
            await generateNotifications(notificationType);
        }
    } catch (error) {
        console.error(`Error fetching ${sportType} news:`, error);
        throw error;
    }
};
