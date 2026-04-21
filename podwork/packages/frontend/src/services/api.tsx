/* 
api.tsx
Colin Treanor
This file contains calls to the server that are needed for the frontend
- Login
- Sign up 
- Save selected preferences
*/
const SERVER = 'https://www.polypod.net:3000';

export const registerUser = async (payload: any, deviceId?: string) => {
    const requestBody = deviceId ? { ...payload, deviceId } : payload;
    const response = await fetch(`${SERVER}/user/add`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(requestBody),
    });
    return response;
};

export const loginUser = async (username: string, password: string, deviceId?: string) => {
    const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        'x-password': password,
    };

    if (deviceId) {
        headers['x-device-id'] = deviceId;
    }

    const response = await fetch(`${SERVER}/user/${username}`, {
        method: 'GET',
        headers,
    });
    return response;
};

export const savePreferencesToDatabase = async (userId: string, selectedIds: string[]) => {
    const payload = {
        updated_user: {
            interests: selectedIds.map(name => ({ name: name }))
        }
    };

    const response = await fetch(`${SERVER}/user/${userId}`, {
        method: 'PUT',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload),
    });

    return response;
};

export const handleSaveDeviceIds = async (userId: string, deviceids: string[]) => {
    const payload = {
        updated_user: {
            deviceids: deviceids
        }
    };

    const response = await fetch(`${SERVER}/user/${userId}`, {
        method: 'PUT',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload),
    });

    return response;
};

export const getAvailableInterests = async () => {
    const response = await fetch(`${SERVER}/interests`); 

    if (!response.ok) {
      throw new Error('Network response was not ok');
    }

    return response.json();
};

export const saveUserLocation = async (userId: number, zipCode: string) => {
    try {
        const response = await fetch(`${SERVER}/user/${userId}/location`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ zip_code: zipCode })
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        return await response.json();
    } catch (error) {
        console.error("Error saving user location:", error);
        throw error;
    }
};