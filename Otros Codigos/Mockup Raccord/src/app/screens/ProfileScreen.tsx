import { useState, useEffect } from "react";
import { useLocation, useNavigate } from "react-router";
import { ArrowLeft, Upload } from "lucide-react";
import logo from "../../imports/Logo_Negativo.png";

const identificacionTypes = ["CC", "NIT", "TI", "PA", "CE"];

export default function ProfileScreen() {
  const location = useLocation();
  const navigate = useNavigate();
  const projectName = location.state?.projectName || "";
  const [profilePhoto, setProfilePhoto] = useState<string | null>(null);

  const [formData, setFormData] = useState({
    nombres: "",
    apellidos: "",
    email: "",
    celular: "",
    tipoIdentificacion: "",
    numeroDocumento: "",
    direccion: "",
    fechaNacimiento: "",
    fechaCreacion: new Date().toISOString().split("T")[0],
    departamento: "",
    proyecto: projectName,
  });

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setProfilePhoto(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Perfil guardado:", { ...formData, foto: profilePhoto });
    // Simular guardado en base de datos
    navigate(-1);
  };

  return (
    <div className="min-h-screen bg-[#0A0A0A]">
      {/* Header */}
      <header className="bg-[#1A1A1A] border-b border-[#2A2A2A] px-8 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate(-1)}
              className="p-2 hover:bg-[#2A2A2A] rounded-lg transition-colors"
            >
              <ArrowLeft className="w-5 h-5 text-[#FAFAFA]" />
            </button>
            <img src={logo} alt="Logo" className="h-10" />
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-4xl mx-auto px-8 py-12">
        <div className="bg-[#1A1A1A] rounded-lg shadow-lg border border-[#2A2A2A] p-8">
          <h1 className="text-[#FAFAFA] mb-8">Perfil de Usuario</h1>

          <form onSubmit={handleSave} className="space-y-6">
            {/* Profile Photo Upload */}
            <div className="flex justify-center mb-8">
              <div className="flex flex-col items-center gap-4">
                <div className="w-32 h-32 rounded-full bg-[#2A2A2A] border-2 border-[#0B4F8A] overflow-hidden flex items-center justify-center">
                  {profilePhoto ? (
                    <img
                      src={profilePhoto}
                      alt="Foto de perfil"
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <Upload className="w-12 h-12 text-[#6B6B6B]" />
                  )}
                </div>
                <label className="cursor-pointer bg-[#0B4F8A] text-white px-4 py-2 rounded-lg hover:bg-[#094170] transition-colors flex items-center gap-2">
                  <Upload className="w-4 h-4" />
                  Subir Foto
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handlePhotoUpload}
                    className="hidden"
                  />
                </label>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block mb-2 text-[#FAFAFA]">Nombres</label>
                <input
                  type="text"
                  name="nombres"
                  value={formData.nombres}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                  placeholder="Ingresa tus nombres"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">Apellidos</label>
                <input
                  type="text"
                  name="apellidos"
                  value={formData.apellidos}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                  placeholder="Ingresa tus apellidos"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">Email</label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                  placeholder="correo@ejemplo.com"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">Celular</label>
                <input
                  type="tel"
                  name="celular"
                  value={formData.celular}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                  placeholder="Número de celular"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">
                  Tipo de Identificación
                </label>
                <select
                  name="tipoIdentificacion"
                  value={formData.tipoIdentificacion}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                >
                  <option value="">Seleccione tipo</option>
                  {identificacionTypes.map((type) => (
                    <option key={type} value={type}>
                      {type}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">
                  Número de Documento
                </label>
                <input
                  type="text"
                  name="numeroDocumento"
                  value={formData.numeroDocumento}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                  placeholder="Número de documento"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">
                  Dirección de Residencia
                </label>
                <input
                  type="text"
                  name="direccion"
                  value={formData.direccion}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                  placeholder="Dirección completa"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">
                  Fecha de Nacimiento
                </label>
                <input
                  type="date"
                  name="fechaNacimiento"
                  value={formData.fechaNacimiento}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">
                  Fecha de Creación del Perfil
                </label>
                <input
                  type="date"
                  name="fechaCreacion"
                  value={formData.fechaCreacion}
                  disabled
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg bg-[#2A2A2A] text-[#6B6B6B] cursor-not-allowed"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">
                  Nombre del Departamento
                </label>
                <input
                  type="text"
                  name="departamento"
                  value={formData.departamento}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                  placeholder="Departamento al que pertenece"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">
                  Nombre del Proyecto
                </label>
                <input
                  type="text"
                  name="proyecto"
                  value={formData.proyecto}
                  disabled
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg bg-[#2A2A2A] text-[#6B6B6B] cursor-not-allowed"
                />
              </div>
            </div>

            <div className="flex justify-end pt-4">
              <button
                type="submit"
                className="bg-[#0B4F8A] text-white px-8 py-3 rounded-lg hover:bg-[#094170] transition-colors"
              >
                Guardar Cambios
              </button>
            </div>
          </form>
        </div>
      </main>
    </div>
  );
}
