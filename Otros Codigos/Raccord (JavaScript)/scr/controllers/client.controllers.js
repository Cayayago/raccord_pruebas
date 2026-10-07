import pool from '../db.js'

//Get
export const getClients = async (req, res) =>{try { const result = await pool.query('SELECT * FROM clients'); res.json(result.rows)} catch(error){return res.status(500).json({mensaje:'Algo salio mal'})}}

export const getclient = async (req, res) => {try {const { id } = req.params; const result = await pool.query('SELECT * FROM clients WHERE id_cliente=$1', [id]);
    if(result.rows.length === 0) return res.status(404).json({mensaje:'Cliente no encontrado'});res.json(result.rows[0])} catch(error) {return res.status(500).json({mensaje:'Algo salio mal'})}}

//Post
export const createClient = async (req, res) => {try { const {document, id_document, razon_social, representante_legal, email, address, telephone, number_cellphone} = req.body;
const result = await pool.query('INSERT INTO clients (document, id_document, razon_social, representante_legal, email, address, telephone, number_cellphone) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *',
    [document, id_document, razon_social, representante_legal, email, address, telephone, number_cellphone]); res.json(result.rows[0])} catch(error){return res.status(500).json({mensaje:'Algo salio mal'})}}

//Patch
export const updateClient = async (req, res) =>{try { const { id } = req.params; const { document, id_document, razon_social, representante_legal, email, address, telephone, number_cellphone } = req.body; const
    result = await pool.query('UPDATE clients SET document=coalesce($1, document), id_document=coalesce($2,id_document), razon_social=coalesce($3,razon_social), representante_legal=coalesce($4,representante_legal), email=coalesce($5,email), address=coalesce($6,address), telephone=coalesce($7,telephone), number_cellphone=coalesce($8,number_cellphone) WHERE id_cliente =$9 RETURNING *',
    [document, id_document, razon_social, representante_legal, email, address, telephone, number_cellphone, id]);if(result.rows.length === 0) return res.status(404).json({mensaje:'Clinete no encontrado'});res.json(result.rows[0]) 
    }catch(error){return res.status(500).json({mensaje:'Algo salio mal'})}}

//Delete
export const deleteClient = async (req, res) =>{try { const { id } = req.params; await pool.query('DELETE FROM clients WHERE id_cliente=$1', [id]);
    res.json({ mensaje: 'Cliente eliminado correctamente' })} catch (error) {return res.status(500).json({mensaje:'Algo salio mal'})}}
