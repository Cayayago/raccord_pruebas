import {Router} from 'express'
import {getClients, getclient, createClient, updateClient, deleteClient} from '../controllers/client.controllers.js'

const router = Router()

//Get
router.get('/client',getClients)

router.get('/client/:id', getclient)

//Post
router.post('/client',createClient )

//put
router.patch('/client/:id',updateClient )

//Delete
router.delete('/client/:id',deleteClient )

export default router