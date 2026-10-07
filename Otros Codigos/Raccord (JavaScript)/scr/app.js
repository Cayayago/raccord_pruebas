import express from 'express'
import usersraccord from './routes/users.routes.js'
import proyectos from './routes/project.routes.js'
import clientes from './routes/client.routes.js'


const app = express()
app.use(express.json())


app.use(usersraccord)
app.use(proyectos)
app.use(clientes)

app.use((req, res, next) =>{res.status(404).json({Message:'Ruta no encontrada'})})

export default app;