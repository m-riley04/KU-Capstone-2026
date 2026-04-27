import { eventData } from "../models/notifications";
import { getLatestEventByInterestName } from "../repositories/event_quaries";
import { getInterestsFromDatabase } from "../repositories/interests_queries";
import { EspnScoreboardEvent } from "../clients/ESPN-client";

export const getPreviousEspnScoreboardData: (scoreboard: string) => Promise<eventData | null> = async (scoreboard: string) => {
    try {
        const previousData = await getLatestEventByInterestName(1, scoreboard);
        if (!previousData) {
            console.log('No previous ESPN scoreboard data found in the database.');
            return null;
        }

        return previousData;
    } catch (error) {
        console.error('Error fetching previous ESPN scoreboard data:', error);
        throw error;
    }
}

export const espnScoreboardHasChanged = (currentData: eventData, oldData: eventData | null): boolean => {
    if (!oldData) {
        return true;
    }

    return currentData.headline !== oldData.headline || currentData.info !== oldData.info;
}

export const getInterestNamesByCategory = async (category: string): Promise<string[]> => {
    const interests = await getInterestsFromDatabase(1);
    return interests
        .filter((interest: { category: string; name: string }) => interest.category === category)
        .map((interest: { name: string }) => interest.name);
}

const normalizeTeamName = (teamName: string): string => {
    return teamName
        .toLowerCase()
        .replace(/[^a-z0-9\s]/g, '')
        .replace(/\s+/g, ' ')
        .trim();
}

const TEAM_ALIASES: Record<string, string[]> = {
    'la clippers': ['los angeles clippers'],
    'los angeles clippers': ['la clippers'],
};

const buildComparableTeamNames = (team: {
    displayName?: string;
    shortDisplayName?: string;
    abbreviation?: string;
    name?: string;
    location?: string;
    nickname?: string;
} | undefined): string[] => {
    if (!team) {
        return [];
    }

    const rawCandidates = [
        team.displayName,
        team.shortDisplayName,
        team.abbreviation,
        team.name,
        team.location,
        team.nickname,
        team.location && team.nickname ? `${team.location} ${team.nickname}` : undefined,
    ].filter((value): value is string => Boolean(value));

    const normalized = rawCandidates.map(normalizeTeamName);
    const withAliases = normalized.flatMap((candidate) => [candidate, ...(TEAM_ALIASES[candidate] ?? [])]);
    return Array.from(new Set(withAliases));
}

export const doesEventInvolveInterestTeam = (event: EspnScoreboardEvent, teamInterestName: string): boolean => {
    const normalizedInterest = normalizeTeamName(teamInterestName);
    const interestAliases = TEAM_ALIASES[normalizedInterest] ?? [];
    const acceptedInterestNames = new Set([normalizedInterest, ...interestAliases]);

    const competition = event.competitions?.[0];
    const competitors = competition?.competitors ?? [];

    return competitors.some((competitor) => {
        const comparableNames = buildComparableTeamNames(competitor.team);
        return comparableNames.some((name) => acceptedInterestNames.has(name));
    });
}

export const filterScoreboardEventsByTeamInterest = (
    events: EspnScoreboardEvent[],
    teamInterestNames: string[],
): Record<string, EspnScoreboardEvent[]> => {
    const filteredByTeam: Record<string, EspnScoreboardEvent[]> = {};

    for (const teamInterestName of teamInterestNames) {
        const matchingEvents = events.filter((event) => doesEventInvolveInterestTeam(event, teamInterestName));
        if (matchingEvents.length > 0) {
            filteredByTeam[teamInterestName] = matchingEvents;
        }
    }

    return filteredByTeam;
}
