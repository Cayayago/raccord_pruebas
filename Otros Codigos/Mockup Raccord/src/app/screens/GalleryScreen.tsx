import { useState } from "react";
import { useNavigate, useLocation } from "react-router";
import { ArrowLeft, Menu, User, Globe, Search, X, LogOut } from "lucide-react";
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

type PhotoType = "Propuesta" | "Prueba" | "Set" | "Todos";

const mockCharacters = [
  { codigo: "P001", nombre: "María" },
  { codigo: "P002", nombre: "Roberto" },
  { codigo: "P003", nombre: "Ana" },
];

const mockScenes = [
  { numero: "1", nombre: "María en la cabaña" },
  { numero: "2", nombre: "Sombras en el bosque" },
  { numero: "3", nombre: "La huida al amanecer" },
];

interface GalleryPhoto {
  id: string;
  url: string;
  personaje: string;
  personajeNombre: string;
  escena: string;
  escenaNombre: string;
  descripcion: string;
  notas: string;
  tipo: "Propuesta" | "Prueba" | "Set";
}

// Mock data - debería venir del estado global
const mockGalleryPhotos: GalleryPhoto[] = [
  {
    id: "1",
    url: "https://via.placeholder.com/400x300/0B4F8A/FFFFFF?text=Foto+1",
    personaje: "P001",
    personajeNombre: "María",
    escena: "1",
    escenaNombre: "María en la cabaña",
    descripcion: "María mirando por la ventana",
    notas: "Vestuario: Suéter gris, Iluminación natural",
    tipo: "Set",
  },
  {
    id: "2",
    url: "https://via.placeholder.com/400x300/7B5FCF/FFFFFF?text=Foto+2",
    personaje: "P001",
    personajeNombre: "María",
    escena: "1",
    escenaNombre: "María en la cabaña",
    descripcion: "Primer plano de María",
    notas: "Maquillaje: Lágrimas en mejilla derecha",
    tipo: "Propuesta",
  },
  {
    id: "3",
    url: "https://via.placeholder.com/400x300/E67E5C/FFFFFF?text=Foto+3",
    personaje: "P002",
    personajeNombre: "Roberto",
    escena: "2",
    escenaNombre: "Sombras en el bosque",
    descripcion: "Roberto caminando entre árboles",
    notas: "Vestuario oscuro, Props: linterna",
    tipo: "Prueba",
  },
];

export default function GalleryScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const projectName = location.state?.projectName || "Proyecto";
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  const [filterPersonaje, setFilterPersonaje] = useState("");
  const [filterEscena, setFilterEscena] = useState("");
  const [filterTipo, setFilterTipo] = useState<PhotoType>("Todos");
  const [selectedPhoto, setSelectedPhoto] = useState<GalleryPhoto | null>(null);
  const [showCharacterSuggestions, setShowCharacterSuggestions] = useState(false);
  const [showSceneSuggestions, setShowSceneSuggestions] = useState(false);
  const [filteredCharacters, setFilteredCharacters] = useState(mockCharacters);
  const [filteredScenes, setFilteredScenes] = useState(mockScenes);

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

  const handlePersonajeInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setFilterPersonaje(value);

    const filtered = mockCharacters.filter(
      (char) =>
        char.codigo.toLowerCase().includes(value.toLowerCase()) ||
        char.nombre.toLowerCase().includes(value.toLowerCase())
    );
    setFilteredCharacters(filtered);
    setShowCharacterSuggestions(value.length > 0);
  };

  const handleSelectCharacter = (codigo: string, nombre: string) => {
    setFilterPersonaje(`${codigo} - ${nombre}`);
    setShowCharacterSuggestions(false);
  };

  const handleEscenaInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setFilterEscena(value);

    const filtered = mockScenes.filter(
      (scene) =>
        scene.numero.includes(value) ||
        scene.nombre.toLowerCase().includes(value.toLowerCase())
    );
    setFilteredScenes(filtered);
    setShowSceneSuggestions(value.length > 0);
  };

  const handleSelectScene = (numero: string, nombre: string) => {
    setFilterEscena(`Escena #${numero} - ${nombre}`);
    setShowSceneSuggestions(false);
  };

  const filteredPhotos = mockGalleryPhotos.filter((photo) => {
    // Extract just the search term (handle both "P001 - Maria" format and plain text)
    const personajeSearchTerm = filterPersonaje.split(" - ")[0] || filterPersonaje;
    const escenaSearchTerm = filterEscena.replace("Escena #", "").split(" - ")[0] || filterEscena;

    const matchPersonaje = filterPersonaje
      ? photo.personaje.toLowerCase().includes(personajeSearchTerm.toLowerCase()) ||
        photo.personajeNombre.toLowerCase().includes(personajeSearchTerm.toLowerCase())
      : true;
    const matchEscena = filterEscena
      ? photo.escena.includes(escenaSearchTerm) ||
        photo.escenaNombre.toLowerCase().includes(escenaSearchTerm.toLowerCase())
      : true;
    const matchTipo = filterTipo === "Todos" ? true : photo.tipo === filterTipo;

    return matchPersonaje && matchEscena && matchTipo;
  });

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
          <h2 className="text-[#FAFAFA]">{projectName} - Galería</h2>
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
        {/* Filters */}
        <div className="mb-8 grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Personaje Filter with Autocomplete */}
          <div className="relative">
            <input
              type="text"
              value={filterPersonaje}
              onChange={handlePersonajeInputChange}
              onFocus={() => filterPersonaje && setShowCharacterSuggestions(true)}
              onBlur={() => setTimeout(() => setShowCharacterSuggestions(false), 200)}
              className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg bg-[#1A1A1A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A]"
              placeholder="Todos los personajes"
            />
            {showCharacterSuggestions && filteredCharacters.length > 0 && (
              <div className="absolute top-full mt-1 w-full bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg shadow-lg z-10 max-h-48 overflow-y-auto">
                <button
                  type="button"
                  onClick={() => {
                    setFilterPersonaje("");
                    setShowCharacterSuggestions(false);
                  }}
                  className="w-full px-4 py-2 text-left text-[#6B6B6B] hover:bg-[#2A2A2A] transition-colors border-b border-[#2A2A2A]"
                >
                  Todos los personajes
                </button>
                {filteredCharacters.map((char) => (
                  <button
                    key={char.codigo}
                    type="button"
                    onClick={() => handleSelectCharacter(char.codigo, char.nombre)}
                    className="w-full px-4 py-2 text-left text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors flex items-center justify-between"
                  >
                    <span>{char.codigo}</span>
                    <span className="text-[#6B6B6B] text-sm">{char.nombre}</span>
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Escena Filter with Autocomplete */}
          <div className="relative">
            <input
              type="text"
              value={filterEscena}
              onChange={handleEscenaInputChange}
              onFocus={() => filterEscena && setShowSceneSuggestions(true)}
              onBlur={() => setTimeout(() => setShowSceneSuggestions(false), 200)}
              className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg bg-[#1A1A1A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A]"
              placeholder="Todas las escenas"
            />
            {showSceneSuggestions && filteredScenes.length > 0 && (
              <div className="absolute top-full mt-1 w-full bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg shadow-lg z-10 max-h-48 overflow-y-auto">
                <button
                  type="button"
                  onClick={() => {
                    setFilterEscena("");
                    setShowSceneSuggestions(false);
                  }}
                  className="w-full px-4 py-2 text-left text-[#6B6B6B] hover:bg-[#2A2A2A] transition-colors border-b border-[#2A2A2A]"
                >
                  Todas las escenas
                </button>
                {filteredScenes.map((scene) => (
                  <button
                    key={scene.numero}
                    type="button"
                    onClick={() => handleSelectScene(scene.numero, scene.nombre)}
                    className="w-full px-4 py-2 text-left text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors"
                  >
                    Escena #{scene.numero} - {scene.nombre}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Tipo Filter - Keep as Select */}
          <select
            value={filterTipo}
            onChange={(e) => setFilterTipo(e.target.value as PhotoType)}
            className="px-4 py-3 border border-[#2A2A2A] rounded-lg bg-[#1A1A1A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A]"
          >
            <option value="Todos">Todos los tipos</option>
            <option value="Set">Set</option>
            <option value="Propuesta">Propuesta</option>
            <option value="Prueba">Prueba</option>
          </select>
        </div>

        {/* Gallery Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {filteredPhotos.map((photo) => (
            <div
              key={photo.id}
              onClick={() => setSelectedPhoto(photo)}
              className="bg-[#1A1A1A] rounded-lg border border-[#2A2A2A] overflow-hidden hover:border-[#0B4F8A] transition-colors cursor-pointer"
            >
              <img
                src={photo.url}
                alt={photo.descripcion}
                className="w-full h-48 object-cover"
              />
              <div className="p-4">
                <span
                  className="inline-block px-3 py-1 rounded-full text-xs text-white mb-2"
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
                <p className="text-[#FAFAFA] text-sm mb-1">
                  Escena #{photo.escena}
                </p>
                <p className="text-[#6B6B6B] text-xs">{photo.personajeNombre}</p>
              </div>
            </div>
          ))}
        </div>

        {filteredPhotos.length === 0 && (
          <div className="text-center py-12">
            <p className="text-[#6B6B6B]">No se encontraron fotos</p>
          </div>
        )}
      </main>

      {/* Photo Detail Modal */}
      {selectedPhoto && (
        <div
          className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-8"
          onClick={() => setSelectedPhoto(null)}
        >
          <div
            className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-6">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-[#FAFAFA] text-xl">Detalles de la Foto</h3>
                <button
                  onClick={() => setSelectedPhoto(null)}
                  className="text-[#6B6B6B] hover:text-[#FAFAFA]"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <img
                  src={selectedPhoto.url}
                  alt={selectedPhoto.descripcion}
                  className="w-full rounded-lg"
                />

                <div className="space-y-4">
                  <div>
                    <span
                      className="inline-block px-3 py-1 rounded-full text-xs text-white"
                      style={{
                        backgroundColor:
                          selectedPhoto.tipo === "Set"
                            ? "#4CAF50"
                            : selectedPhoto.tipo === "Propuesta"
                            ? "#0B4F8A"
                            : "#E67E5C",
                      }}
                    >
                      {selectedPhoto.tipo}
                    </span>
                  </div>

                  <div>
                    <p className="text-[#6B6B6B] text-sm mb-1">Escena</p>
                    <p className="text-[#FAFAFA]">
                      #{selectedPhoto.escena} - {selectedPhoto.escenaNombre}
                    </p>
                  </div>

                  <div>
                    <p className="text-[#6B6B6B] text-sm mb-1">Personaje</p>
                    <p className="text-[#FAFAFA]">
                      {selectedPhoto.personaje} - {selectedPhoto.personajeNombre}
                    </p>
                  </div>

                  <div>
                    <p className="text-[#6B6B6B] text-sm mb-1">Descripción</p>
                    <p className="text-[#FAFAFA]">{selectedPhoto.descripcion}</p>
                  </div>

                  {selectedPhoto.notas && (
                    <div>
                      <p className="text-[#6B6B6B] text-sm mb-1">
                        Notas de Continuidad
                      </p>
                      <p className="text-[#FAFAFA]">{selectedPhoto.notas}</p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
