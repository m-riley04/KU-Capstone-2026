
export interface User {
    id: number;
    username: string;
    email: string;
    password: string;
    created_at: Date;
    updated_at: Date;
}

export interface UserInterests {
    interest_id: number;
    name: string;
    category: InterestCategory;
}

enum InterestCategory {
    SPORTS = 'sports',
    FINANCE = 'finance',
    WEATHER = 'weather',
}