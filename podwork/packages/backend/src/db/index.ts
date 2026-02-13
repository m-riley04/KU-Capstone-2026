import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import { DB_CONFIG } from '../config/database';

export const dbPromise = open({
    filename: DB_CONFIG.filename,
    driver: sqlite3.Database,
});