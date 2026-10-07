import {Router} from 'express'
import {getProjects, getProject, createProject, updateProject, deleteProject} from '../controllers/project.controllers.js'

const router = Router()

//Get
router.get('/project',getProjects)

router.get('/project/:id',getProject)

//Post
router.post('/project',createProject)

//Put
router.patch('/project/:id',updateProject )

//Delete
router.delete('/project/:id', deleteProject)

export default router