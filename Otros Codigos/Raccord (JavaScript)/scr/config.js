import {config} from 'dotenv'

config()

export const PORT = process.env.PORT || 3000
export const DB_Host = process.env.DB_HOST
export const DB_User = process.env.DB_USER
export const DB_Database = process.env.DB_DATABASE
export const DB_Password = process.env.DB_PASSWORD
export const DB_Port = process.env.DB_PORT
