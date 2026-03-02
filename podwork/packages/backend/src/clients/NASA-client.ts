import { eventData } from "../models/notifications";

export const fetchApodData = async () : Promise<eventData> => {
    const apiKey = 'WH2649oaluXd4Wl6SgDPCqK6EVTDlamncHJ7dJvt';
    const url = `https://api.nasa.gov/planetary/apod?api_key=${apiKey}`;
    if (apiKey) {
        try {
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error(`Error fetching APOD data: ${response.statusText}`);
            }
            const data = await response.json();
            return {
                timestamp: data.date,
                media: data.url,
                headline: data.title,
                info: data.explanation,
                from_source: 'NASA',
                seemore: 'https://apod.nasa.gov/apod/astropix.html'
            }
        } catch (error) {
            console.error('Error fetching APOD data:', error);
            throw error;
        }
    } else {
        throw new Error('NASA API key is not defined');
    } }
