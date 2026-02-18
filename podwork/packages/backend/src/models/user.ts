
export interface User {
    id: number;
    username: string;
    email: string;
    password: string;
    interests ?: UserInterests[];
    created_at: Date;
    updated_at: Date;
}

export interface UserInterests {
    id: number;
    name: string;
    category: InterestCategory;
}

enum InterestCategory {
    SPORTS = 'sports',
    FINANCE = 'finance',
    WEATHER = 'weather',
}