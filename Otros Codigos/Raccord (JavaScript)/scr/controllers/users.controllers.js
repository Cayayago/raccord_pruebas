import pool from '../db.js'

//Get
export const getUsers = async (req, res) => {
    try{const result = await pool.query('SELECT * FROM users');
        res.json(result.rows)} catch(error){return res.status(500).json({mensaje: 'Algo salio mal'})}}

export const getUser = async (req, res) => {try {const { id } = req.params; const result = await pool.query('SELECT * FROM users WHERE id_user=$1', [id]); 
    if(result.rows.length === 0) return res.status(404).json({mensaje:'usuario no encontrado'}); res.json(result.rows[0])} catch(error){return res.status(500).json({mensaje:'Algo salio mal'})}}


//Post
export const createUser = async (req, res) => {try { const { nombre, apellido, identificacion, id_identificacion, mail, msisdn, direccion, fecha_de_nacimiento,
    estado, fecha_de_creacion,ultimo_acceso, contrasena, id_departamento, id_project, id_rol } = req.body;const hashedPassword = await bcrypt.hash(contrasena, 10)
    const result = await pool.query('INSERT INTO users (nombre, apellido, identificacion, id_identificacion, mail, msisdn, direccion, fecha_de_nacimiento,estado, fecha_de_creacion, ultimo_acceso, contrasena, id_departamento, id_project, id_rol ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15) RETURNING *', 
    [nombre, apellido, identificacion, id_identificacion, mail, msisdn, direccion, fecha_de_nacimiento,
    estado, fecha_de_creacion,ultimo_acceso, contrasena, id_departamento, id_project, id_rol]); res.json(result.rows[0])} catch(error){return res.status(500).json({mensaje:'Algo salio mal'})}}


//Patch
export const updateUser = async (req, res) => {try { const { id } = req.params; const {nombre, apellido, identificacion, id_identificacion, mail, msisdn, direccion, fecha_de_nacimiento, estado, fecha_de_creacion,ultimo_acceso, contrasena, id_departamento, id_project, id_rol } = req.body;
    const result = await pool.query('UPDATE users SET nombre = coalesce ($1, nombre) ,apellido=coalesce($2, apellido) ,identificacion=coalesce($3, identificacion) , id_identificacion=coalesce($4, id_identificacion), mail=coalesce($5, mail), msisdn=coalesce($6, msisdn), direccion=coalesce($7, direccion), fecha_de_nacimiento=coalesce($8 fecha_de_nacimiento),estado=coalesce($9, estado), fecha_de_creacion=coalesce($10, fecha_de_creacion) ,ultimo_acceso=coalesce($11,ultimo_acceso), contrasena=coalesce($12, contrasena), id_departamento=coalesce($13, id_departamento), id_project=coalesce($14,id_project), id_rol=coalesce($15,id_rol) WHERE id_user=$16 RETURNING *', 
    [nombre, apellido, identificacion, id_identificacion, mail, msisdn, direccion, fecha_de_nacimiento, estado, fecha_de_creacion,ultimo_acceso, contrasena, id_departamento, id_project, id_rol, id]);
    if(result.rows.length === 0) return res.status(404).json({mensaje:'Usario no encontrado'}); res.json(result.rows[0])} catch(error){return res.status(500).json({mensaje:'Algo salio mal'})}}

//Delete

export const deleteUser = async (req, res) => {try { const { id } = req.params; await pool.query('DELETE FROM users WHERE id_user=$1', [id]); res.json({ mensaje: 'Usuario eliminado correctamente' })} catch(error){return res.status(500).json({mensaje:'Algo salio mal'})}}