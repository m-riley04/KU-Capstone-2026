import fs from "fs";
import path from "path";
import { connectionType, createDbConnect } from ".";

export const runMigrations = async () => {
    const db = await createDbConnect(1);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    await db.exec(`
        CREATE TABLE IF NOT EXISTS migrations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    `);
    await db.close();

    const migration_file = path.join(__dirname, "migrations");
    const migrationFiles = fs.readdirSync(migration_file).filter(file => file.endsWith('.sql'));

    for (const file of migrationFiles) {
        const migrationName = path.basename(file, '.sql');
        const db = await createDbConnect(connectionType.DEV);
        if (!db) {
            throw new Error('Failed to connect to database');
        }
        const existingMigration = await db.get(`SELECT * FROM migrations WHERE name = ?`, migrationName);
        if (!existingMigration) {
            const migrationSQL = fs.readFileSync(path.join(migration_file, file), 'utf-8');
            await db.exec(migrationSQL);
            await db.run(`INSERT INTO migrations (name) VALUES (?)`, migrationName);
        }
        await db.close();
    }
};