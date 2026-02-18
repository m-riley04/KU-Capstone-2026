import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import path from 'path';
import fs from "fs";

export const enum connectionType {
    TEST,
    DEV
}

export const createDbConnect = async (connection: connectionType) => {
    if (connection === connectionType.TEST) {
        const dbDir = path.join(__dirname, "..", "..", "data");
        console.log("Current Directory:", __dirname);
        console.log("DB Directory:", dbDir);

        const db = await open({
            filename: dbDir + '/podwork_test.db',
            driver: sqlite3.Database,
        });
        await db.exec(`
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT NOT NULL UNIQUE,
                password TEXT NOT NULL,
                username TEXT NOT NULL UNIQUE,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        `);
        return db;
    } 
    if (connection === connectionType.DEV) {
        const dbDir = path.join(__dirname, "..", "..", "data");
        return open({
            filename: path.join(dbDir, 'podwork.db'),
            driver: sqlite3.Database,
        });
    }
};

