
const SERVER = 'http://localhost:3000';

export const registerUser = async (payload: any) => {
    const response = await fetch(`${SERVER}/user/add`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload),
    });
    return response;
};

export const loginUser = async (username: string, password: string) => {
    const response = await fetch(`${SERVER}/user/${username}`, {
        method: 'GET',
        headers: { 
            'Content-Type': 'application/json',
            'x-password': password
        },
    });
    return response;
};

export const savePreferencesToDatabase = async (userId: string, selectedIds: string[]) => {
    const payload = {
        updated_user: {
            interests: selectedIds.map(name => ({ name: name }))
        }
    };

    const response = await fetch(`http://localhost:3000/user/${userId}`, {
        method: 'PUT',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload),
    });

    return response;
};