import path from "path";
import fs from "fs";
import { connectionType, createDbConnect } from ".";

export const runMigrations = async (connection: connectionType) => {
    const db = await createDbConnect(connection);
    if (!db) throw new Error("Failed to connect");

    await db.exec(`
        CREATE TABLE IF NOT EXISTS migrations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    `);

    const migrationPath = path.join(__dirname, "migrations");
    const migrationFiles = fs
        .readdirSync(migrationPath)
        .filter(file => file.endsWith(".sql"))
        .sort();

    for (const file of migrationFiles) {
        const migrationName = path.basename(file, ".sql");

        const existing = await db.get(
            `SELECT * FROM migrations WHERE name = ?`,
            migrationName
        );

        if (!existing) {
            const sql = fs.readFileSync(
                path.join(migrationPath, file),
                "utf-8"
            );

            await db.exec(sql);
            await db.run(
                `INSERT INTO migrations (name) VALUES (?)`,
                migrationName
            );

            console.log(`Applied migration: ${migrationName}`);
        }
    }

    await db.close();
};