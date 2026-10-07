import { useState } from "react";
import { useNavigate, useLocation } from "react-router";
import { ArrowLeft, Menu, User, Globe, LogOut } from "lucide-react";
import logo from "../../imports/Logo_Negativo.png";

const menuOptions = [
  "Guión",
  "Crear Escenas",
  "Crear Personajes",
  "Crew List",
  "Plan de Rodaje",
  "Desglose",
  "Galería",
  "Roles",
];

export default function CreateCharacterScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const projectName = location.state?.projectName || "Proyecto";
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);

  const [formData, setFormData] = useState({
    codigo: "",
    nombre: "",
    edad: "",
    actor: "",
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Personaje guardado:", formData);
    navigate(-1);
  };

  const handleMenuOption = (option: string) => {
    setIsMenuOpen(false);
    if (option === "Guión") {
      navigate("/guiones", { state: { projectName } });
    } else if (option === "Crear Escenas") {
      navigate("/crear-escena", { state: { projectName } });
    } else if (option === "Crear Personajes") {
      navigate("/crear-personaje", { state: { projectName } });
    } else if (option === "Crew List") {
      navigate("/crew-list", { state: { projectName } });
    } else if (option === "Galería") {
      navigate("/galeria", { state: { projectName } });
    } else if (option === "Plan de Rodaje") {
      navigate("/plan-de-rodaje", { state: { projectName } });
    } else if (option === "Desglose") {
      navigate("/desglose", { state: { projectName } });
    } else if (option === "Roles") {
      navigate("/roles", { state: { projectName } });
    }
  };

  const handleProfileClick = () => {
    navigate("/perfil", { state: { projectName } });
    setIsProfileMenuOpen(false);
  };

  const handleLogout = () => {
    navigate("/");
    setIsProfileMenuOpen(false);
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
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="ml-4 p-2 hover:bg-[#2A2A2A] rounded-lg transition-colors"
            >
              <Menu className="w-5 h-5 text-[#FAFAFA]" />
            </button>
          </div>
          <h2 className="text-[#FAFAFA]">{projectName}</h2>
          <div className="relative">
            <button
              onClick={() => setIsProfileMenuOpen(!isProfileMenuOpen)}
              className="w-10 h-10 rounded-full bg-[#0B4F8A] flex items-center justify-center hover:bg-[#094170] transition-colors"
            >
              <User className="w-5 h-5 text-white" />
            </button>

            {isProfileMenuOpen && (
              <div className="absolute right-0 mt-2 w-56 bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg shadow-lg py-2 z-50">
                <button
                  onClick={handleProfileClick}
                  className="w-full px-4 py-2 text-left text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors flex items-center gap-3"
                >
                  <User className="w-4 h-4" />
                  Perfil
                </button>
                <button
                  onClick={() => console.log("Cambiar idioma")}
                  className="w-full px-4 py-2 text-left text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors flex items-center gap-3"
                >
                  <Globe className="w-4 h-4" />
                  Cambio de Idioma
                </button>
                <button
                  onClick={handleLogout}
                  className="w-full px-4 py-2 text-left text-red-500 hover:bg-[#2A2A2A] transition-colors flex items-center gap-3"
                >
                  <LogOut className="w-4 h-4" />
                  Salir
                </button>
              </div>
            )}
          </div>
        </div>
      </header>

      {/* Menu Dropdown */}
      {isMenuOpen && (
        <div className="bg-[#1A1A1A] border-b border-[#2A2A2A] px-8 py-2">
          <div className="max-w-7xl mx-auto flex gap-2">
            {menuOptions.map((option) => (
              <button
                key={option}
                onClick={() => handleMenuOption(option)}
                className="px-4 py-2 text-[#FAFAFA] hover:bg-[#2A2A2A] rounded-lg transition-colors"
              >
                {option}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Content */}
      <main className="max-w-3xl mx-auto px-8 py-12">
        <div className="bg-[#1A1A1A] rounded-lg shadow-lg border border-[#2A2A2A] p-8">
          <h1 className="text-[#FAFAFA] mb-8">Crear Personaje</h1>

          <form onSubmit={handleSave} className="space-y-6">
            <div>
              <label className="block mb-2 text-[#FAFAFA]">
                Código del Personaje
              </label>
              <input
                type="text"
                name="codigo"
                value={formData.codigo}
                onChange={handleChange}
                className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                placeholder="Ej: P001, P002"
              />
            </div>

            <div>
              <label className="block mb-2 text-[#FAFAFA]">
                Nombre del Personaje
              </label>
              <input
                type="text"
                name="nombre"
                value={formData.nombre}
                onChange={handleChange}
                className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                placeholder="Nombre del personaje"
              />
            </div>

            <div>
              <label className="block mb-2 text-[#FAFAFA]">Edad</label>
              <input
                type="text"
                name="edad"
                value={formData.edad}
                onChange={handleChange}
                className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                placeholder="Edad del personaje"
              />
            </div>

            <div>
              <label className="block mb-2 text-[#FAFAFA]">
                Actor (Quien le dará vida)
              </label>
              <input
                type="text"
                name="actor"
                value={formData.actor}
                onChange={handleChange}
                className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                placeholder="Nombre del actor"
              />
            </div>

            <div className="flex justify-end pt-4">
              <button
                type="submit"
                className="px-8 py-3 bg-[#0B4F8A] text-white rounded-lg hover:bg-[#094170] transition-colors"
              >
                Guardar
              </button>
            </div>
          </form>
        </div>
      </main>
    </div>
  );
}
