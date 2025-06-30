const mysql = require('mysql2/promise');

const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT || 3306,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    connectionLimit: 10,
    acquireTimeout: 60000,
    timeout: 60000,
    reconnect: true
};

let pool = null;

const getConnection = async () => {
    if (!pool) {
        pool = mysql.createPool(dbConfig);
        console.log('✅ Pool de conexiones MySQL creado');
    }
    return pool;
};

const executeQuery = async (query, params = []) => {
    try {
        const connection = await getConnection();
        const [results] = await connection.execute(query, params);
        return results;
    } catch (error) {
        console.error('❌ Error en consulta a la base de datos:', error);
        throw error;
    }
};

const testConnection = async () => {
    try {
        const connection = await getConnection();
        await connection.execute('SELECT 1');
        console.log('✅ Conexión a MySQL establecida correctamente');
        return true;
    } catch (error) {
        console.error('❌ Error conectando a MySQL:', error);
        return false;
    }
};

module.exports = {
    getConnection,
    executeQuery,
    testConnection
};
