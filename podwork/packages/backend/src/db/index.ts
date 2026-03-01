import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import path from 'path';
import fs from "fs";
import { runMigrations } from './run_migrations';

export const enum connectionType {
    TEST,
    DEV
}

export const createDbConnect = async (connection: connectionType) => {
    if (connection === connectionType.TEST) {
        const dbDir = path.join(__dirname, "..", "..", "data");
        console.log("Hi from part 1")
        const db = await open({
            filename: dbDir + '/podwork_test.db',
            driver: sqlite3.Database,
        });
        console.log("Hi from part 2")
        await runMigrations(connection)
        console.log("Migrations Ran")
        return db;
    } 
    else if (connection === connectionType.DEV) {
        const dbDir = path.join(__dirname, "..", "..", "data");
        return open({
            filename: path.join(dbDir, 'podwork_dev.db'),
            driver: sqlite3.Database,
        });
    }
};

