import pg from 'pg'
import { DB_Host, DB_User, DB_Database, DB_Password, DB_Port } from './config.js'

const { Pool } = pg

const pool = new Pool({
  host: DB_Host,
  port: DB_Port,
  database: DB_Database,
  user: DB_User,
  password: DB_Password,
  ssl: { rejectUnauthorized: false }
})

export default pool