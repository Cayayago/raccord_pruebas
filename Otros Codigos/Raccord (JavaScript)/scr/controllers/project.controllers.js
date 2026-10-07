import pool from '../db.js'

//Get
export const getProjects = async (req, res) => {try { const result = await pool.query('SELECT * FROM projects'); res.json(result.rows)} catch(error){return res.status(500).json({mensaje:'Algo salio mal'})}}

export const getProject = async (req, res) =>{try {const { id } = req.params; const result = await pool.query('SELECT * FROM projects WHERE id_project=$1', [id]);
    if (result.rows.length == 0) return res.status(400).json({mensaje:'Proyecto no encontrado'});res.json(result.rows[0])} catch(error){return res.status(500).json({mensaje:'Algo salio mal'})}}


//Post
export const createProject = async (req, res) =>{try { const {project_name, formato_de_produccion, genero, sinopsis, director, id_client } = req.body; 
    const result = await pool.query('INSERT INTO projects (project_name, formato_de_produccion, genero, sinopsis, director, id_client) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
    [project_name, formato_de_produccion, genero, sinopsis, director, id_client]); res.json(result.rows[0]) 
    }catch(error){return res.status(500).json({Message:'Algo salio mal'})}}
//Patch

export const updateProject = async (req, res) =>{try { const {project_name, formato_de_produccion, genero, sinopsis, director, id_client } = req.params; const { titulo } = req.body; 
    const result = await pool.query('UPDATE projects SET project_name=coalesce($1, project_name), formato_de_produccion=coalesce($2,formato_de_produccion), genero=coalesce($3, genero), sinopsis=coalesce($4, sinopsis), director=coalesce($5,director), id_client=coalesce($6,id_client) WHERE id_project= $7 RETURNING *',
    [project_name, formato_de_produccion, genero, sinopsis, director, id_client, id]);if(result.rows.length === 0) return res.status(404).json({mensaje:'Proyecto no encontrado'}) ;res.json(result.rows[0]) 
    }catch(error){return res.status(500).json({mensaje:'Algo salio mal'})}}

//Delete

export const deleteProject = async (req, res) => {try { const { id } = req.params; await pool.query('DELETE FROM projects WHERE id_project=$1', [id]);
    res.json({ mensaje: 'Proyecto eliminado correctamente' })} catch(error){return res.status(500).json({Message:'Algo salio mal'})}}