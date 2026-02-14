
export interface user {
    id: number;
    username: string;
    email: string;
    password: string;
    created_at: Date;
    updated_at: Date;
}

export interface user_interests {
    interest_id: number;
    name: string;
    category: interest_category;
}

enum interest_category {
    SPORTS = 'sports',
    FINANCE = 'finance',
    WEATHER = 'weather',
}