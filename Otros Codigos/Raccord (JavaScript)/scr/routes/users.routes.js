import {Router} from 'express'
import {getUsers, getUser, createUser, updateUser, deleteUser} from '../controllers/users.controllers.js'
const router = Router()

// Get
router.get('/user', getUsers)

router.get('/user/:id', getUser)

//Post
router.post('/user',createUser)

//Put
router.patch('/user/:id',updateUser )

//Delete
router.delete('/user/:id',deleteUser )

export default router