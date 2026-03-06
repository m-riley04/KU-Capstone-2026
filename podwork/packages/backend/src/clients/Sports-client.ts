import { eventData } from "../models/notifications";

export const fetchCollegeBaskballNews = async (): Promise<eventData> => {
    const url = `https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/news`;
    
    try {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Error fetching college basketball news: ${response.statusText}`);
        }
        const data = await response.json();
        
        // Get the most recent news article
        if (!data.articles || data.articles.length === 0) {
            throw new Error('No articles found in ESPN response');
        }
        
        const latestArticle = data.articles[0];
        
        return {
            timestamp: latestArticle.publishedAt || new Date().toISOString(),
            media: latestArticle.images?.[0]?.url || '',
            headline: latestArticle.headline || 'College Basketball News',
            info: latestArticle.description || latestArticle.summary || '',
            from_source: 'ESPN',
            seemore: latestArticle.links?.[0]?.href || 'https://www.espn.com/mens-college-basketball/'
        };
    } catch (error) {
        console.error('Error fetching college basketball news:', error);
        throw error;
    }
};

export const fetchNFLNews = async (): Promise<eventData> => {
    const url = `https://site.api.espn.com/apis/site/v2/sports/football/nfl/news`;
    
    try {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Error fetching NFL news: ${response.statusText}`);
        }
        const data = await response.json();
        
        if (!data.articles || data.articles.length === 0) {
            throw new Error('No articles found in ESPN response');
        }
        
        const latestArticle = data.articles[0];
        
        return {
            timestamp: latestArticle.publishedAt || new Date().toISOString(),
            media: latestArticle.images?.[0]?.url || '',
            headline: latestArticle.headline || 'NFL News',
            info: latestArticle.description || latestArticle.summary || '',
            from_source: 'ESPN',
            seemore: latestArticle.links?.[0]?.href || 'https://www.espn.com/nfl/'
        };
    } catch (error) {
        console.error('Error fetching NFL news:', error);
        throw error;
    }
};
