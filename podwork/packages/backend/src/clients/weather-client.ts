import { connectionType, createDbConnect } from "../db";
import { eventData } from "../models/notifications";

export const fetchWeatherData = async (location: string): Promise<eventData> => {
    const apiKey = '9433fb5ac42940daa95211856260804'; 
    // &alerts=yes includes severe weather warnings
    const url = `https://api.weatherapi.com/v1/forecast.json?key=${apiKey}&q=${location}&alerts=yes`;

    if (!apiKey) {
        throw new Error('Weather API key is not defined');
    }

    try {
        const response = await fetch(url);

        if (!response.ok) {
            throw new Error(`Error fetching Weather data for ${location}: ${response.statusText}`);
        }

        const data = await response.json();

        const temp = data.current.temp_f;
        const condition = data.current.condition.text;
        const locationName = data.location.name;

        // check if the National Weather Service has issued any active alerts
        const alerts = data.alerts?.alert || [];
        const hasSevereAlert = alerts.length > 0;

        // Default layout for a normal weather day
        let headline = `Weather Update: ${locationName}`;
        let info = `Currently ${temp}°F and ${condition}.`;

        if (hasSevereAlert) {
            // grab the headline of the first active alert
            const alertHeadline = alerts[0].headline; 
            headline = `🚨 WEATHER ALERT: ${locationName}`;
            info = `${alertHeadline} | Currently ${temp}°F.`;
        }

        return {
            timestamp: new Date(),
            media: `https:${data.current.condition.icon}`, 
            headline: headline,
            info: info,
            from_source: 'WeatherAPI',
            seemore: `https://weather.com/weather/today/l/${location}`
        }
    } catch (error) {
        console.error(`Error fetching Weather data for ${location}:`, error);
        throw error;
    }
}

export const getActiveWeatherZipCodes = async (): Promise<string[]> => {
    const db = await createDbConnect(1);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    try {
        // looks at who wants weather, crosses over to the users table, and grabs their zip codes.
        const queryString = `
            SELECT DISTINCT users.zip_code 
            FROM users 
            JOIN user_interests ON users.id = user_interests.user_id
            JOIN interests ON user_interests.interest_id = interests.id
            WHERE interests.name = 'weather_alerts'
            AND users.zip_code IS NOT NULL
        `;

        const result = await db.all(queryString);

        return result.map((row: any) => row.zip_code);

    } catch (error) {
        console.error('Error fetching active weather zip codes:', error);
        throw error; 
    }
}