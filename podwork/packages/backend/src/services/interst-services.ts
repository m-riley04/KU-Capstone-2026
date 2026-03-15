import { getInterestsFromDatabase } from "../repositories/interests_queries";

export const getInterestService = async () => {
    const interests = await getInterestsFromDatabase(1);
    if (!interests) {
        return null;
    }
    const formattedInterests = interests.map((interest) => ({
        id: interest.id,
        name: interest.name,
        category: interest.category
    }));
    return formattedInterests;
}