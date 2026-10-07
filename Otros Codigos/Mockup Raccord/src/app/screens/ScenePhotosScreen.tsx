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

// Mock photos - deberían venir del estado global
const mockPhotos = [
  {
    id: "1",
    url: "https://via.placeholder.com/400x300/0B4F8A/FFFFFF?text=Foto+1",
    personaje: "P001",
    descripcion: "María mirando por la ventana",
    notas: "Vestuario: Suéter gris, Iluminación natural",
    tipo: "Set",
  },
  {
    id: "2",
    url: "https://via.placeholder.com/400x300/7B5FCF/FFFFFF?text=Foto+2",
    personaje: "P001",
    descripcion: "Primer plano de María",
    notas: "Maquillaje: Lágrimas en mejilla derecha",
    tipo: "Propuesta",
  },
];

export default function ScenePhotosScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const { scene, projectName } = location.state || {};
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);

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
          <h2 className="text-[#FAFAFA]">
            Escena #{scene?.numeroEscena} - {scene?.encabezado}
          </h2>
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
      <main className="max-w-7xl mx-auto px-8 py-12">
        <h1 className="text-[#FAFAFA] mb-8">
          Fotos de Continuidad ({mockPhotos.length})
        </h1>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {mockPhotos.map((photo) => (
            <div
              key={photo.id}
              className="bg-[#1A1A1A] rounded-lg border border-[#2A2A2A] overflow-hidden hover:border-[#0B4F8A] transition-colors"
            >
              <img
                src={photo.url}
                alt={photo.descripcion}
                className="w-full h-64 object-cover"
              />
              <div className="p-4 space-y-3">
                <span
                  className="inline-block px-3 py-1 rounded-full text-xs text-white"
                  style={{
                    backgroundColor:
                      photo.tipo === "Set"
                        ? "#4CAF50"
                        : photo.tipo === "Propuesta"
                        ? "#0B4F8A"
                        : "#E67E5C",
                  }}
                >
                  {photo.tipo}
                </span>
                <p className="text-[#FAFAFA]">
                  <span className="text-[#6B6B6B]">Personaje:</span> {photo.personaje}
                </p>
                <p className="text-[#FAFAFA] text-sm">{photo.descripcion}</p>
                {photo.notas && (
                  <p className="text-[#6B6B6B] text-sm">{photo.notas}</p>
                )}
              </div>
            </div>
          ))}
        </div>

        {mockPhotos.length === 0 && (
          <div className="text-center py-12">
            <p className="text-[#6B6B6B]">No hay fotos para esta escena</p>
          </div>
        )}
      </main>
    </div>
  );
}
