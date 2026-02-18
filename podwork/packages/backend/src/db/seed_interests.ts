import { connectionType, createDbConnect } from ".";
import fs from 'fs';
import xml2js from 'xml2js';

export const seedInterests = async () => {
    const db = await createDbConnect(1);
    if (!db) {
        throw new Error('Failed to connect to database');
    }
    

const parser = new xml2js.Parser();
fs.readFile('./data.xml', 'utf8', (err, xmlData) => {
    if (err) return console.error(err);
    parser.parseString(xmlData, (err: Error | null, result: any) => {
    result.interestData.category.forEach(async (category: any) => {
        category.item.forEach(async (item: any) => {
            const name = item.id[0];
            const categoryName = category.$.name;
            try {
                await db.run(
                    `INSERT INTO interests (name, category) VALUES (?, ?)`,
                    name,
                    categoryName
                );
            } catch (error: any) {
                if (error.code === 'SQLITE_CONSTRAINT' && error.message.includes('name')) {
                    console.log(`Interest "${name}" already exists. Skipping.`);
                } else {
                    console.error(`Error inserting interest "${name}":`, error);
                }
            }
        });
    });
    });
});
    

}