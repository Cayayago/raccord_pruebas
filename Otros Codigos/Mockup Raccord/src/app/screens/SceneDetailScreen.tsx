import { useState } from "react";
import { useNavigate, useLocation } from "react-router";
import { ArrowLeft, Menu, User, Globe, Upload, X, LogOut } from "lucide-react";
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

const mockCharacters = [
  { codigo: "P001", nombre: "María" },
  { codigo: "P002", nombre: "Roberto" },
  { codigo: "P003", nombre: "Ana" },
];

type PhotoType = "Propuesta" | "Prueba" | "Set";

interface ScenePhoto {
  id: string;
  url: string;
  personaje: string;
  descripcion: string;
  notas: string;
  tipo: PhotoType;
}

export default function SceneDetailScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const { scene, projectName } = location.state || {};
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  const [photos, setPhotos] = useState<ScenePhoto[]>([]);
  const [currentPhoto, setCurrentPhoto] = useState({
    personaje: "",
    descripcion: "",
    notas: "",
    tipo: "Set" as PhotoType,
  });
  const [showCharacterSuggestions, setShowCharacterSuggestions] = useState(false);
  const [filteredCharacters, setFilteredCharacters] = useState(mockCharacters);

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

  const handlePersonajeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setCurrentPhoto({ ...currentPhoto, personaje: value });

    const filtered = mockCharacters.filter(
      (char) =>
        char.codigo.toLowerCase().includes(value.toLowerCase()) ||
        char.nombre.toLowerCase().includes(value.toLowerCase())
    );
    setFilteredCharacters(filtered);
    setShowCharacterSuggestions(value.length > 0);
  };

  const handleSelectCharacter = (codigo: string) => {
    setCurrentPhoto({ ...currentPhoto, personaje: codigo });
    setShowCharacterSuggestions(false);
  };

  const handleProfileClick = () => {
    navigate("/perfil", { state: { projectName } });
    setIsProfileMenuOpen(false);
  };

  const handleLogout = () => {
    navigate("/");
    setIsProfileMenuOpen(false);
  };

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files) {
      Array.from(files).forEach((file) => {
        const reader = new FileReader();
        reader.onloadend = () => {
          const newPhoto: ScenePhoto = {
            id: Date.now().toString() + Math.random(),
            url: reader.result as string,
            personaje: currentPhoto.personaje,
            descripcion: currentPhoto.descripcion,
            notas: currentPhoto.notas,
            tipo: currentPhoto.tipo,
          };
          setPhotos((prevPhotos) => [...prevPhotos, newPhoto]);
        };
        reader.readAsDataURL(file);
      });
      setCurrentPhoto({ personaje: "", descripcion: "", notas: "", tipo: "Set" });
    }
  };

  const handleRemovePhoto = (id: string) => {
    setPhotos(photos.filter((p) => p.id !== id));
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
          <h2 className="text-[#FAFAFA]">{projectName} - Continuidad Visual</h2>
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
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Scene Information - Read Only */}
          <div className="bg-[#1A1A1A] rounded-lg shadow-lg border border-[#2A2A2A] p-8">
            <h2 className="text-[#FAFAFA] mb-6 text-xl">Información de la Escena</h2>

            <div className="space-y-4">
              <div>
                <label className="block mb-2 text-[#6B6B6B] text-sm">Escena</label>
                <div className="px-4 py-3 bg-[#2A2A2A] rounded-lg text-[#FAFAFA]">
                  #{scene?.numeroEscena}
                </div>
              </div>

              <div>
                <label className="block mb-2 text-[#6B6B6B] text-sm">Encabezado</label>
                <div className="px-4 py-3 bg-[#2A2A2A] rounded-lg text-[#FAFAFA]">
                  {scene?.encabezado}
                </div>
              </div>

              <div>
                <label className="block mb-2 text-[#6B6B6B] text-sm">Día Dramático</label>
                <div className="px-4 py-3 bg-[#2A2A2A] rounded-lg text-[#FAFAFA]">
                  {scene?.diaDramatico}
                </div>
              </div>

              <div>
                <label className="block mb-2 text-[#6B6B6B] text-sm">Ciudad</label>
                <div className="px-4 py-3 bg-[#2A2A2A] rounded-lg text-[#FAFAFA]">
                  {scene?.ciudad}
                </div>
              </div>

              <div>
                <label className="block mb-2 text-[#6B6B6B] text-sm">Fecha de Grabación</label>
                <div className="px-4 py-3 bg-[#2A2A2A] rounded-lg text-[#FAFAFA]">
                  {scene?.fechaGrabacion}
                </div>
              </div>

              <div>
                <label className="block mb-2 text-[#6B6B6B] text-sm">Estado</label>
                <div className="px-4 py-3 bg-[#2A2A2A] rounded-lg text-[#FAFAFA]">
                  {scene?.status}
                </div>
              </div>

              <div className="md:col-span-2">
                <label className="block mb-2 text-[#6B6B6B] text-sm">Personajes</label>
                <div className="px-4 py-3 bg-[#2A2A2A] rounded-lg text-[#FAFAFA]">
                  {scene?.personajes || "P001 - María, P002 - Roberto"}
                </div>
              </div>
            </div>
          </div>

          {/* Photo Upload and Management */}
          <div className="bg-[#1A1A1A] rounded-lg shadow-lg border border-[#2A2A2A] p-8">
            <h2 className="text-[#FAFAFA] mb-6 text-xl">Continuidad Visual</h2>

            {/* Upload Form */}
            <div className="mb-8 p-6 bg-[#2A2A2A] rounded-lg">
              <h3 className="text-[#FAFAFA] mb-4">Subir Nueva Foto</h3>

              <div className="space-y-4">
                <div>
                  <label className="block mb-2 text-[#FAFAFA] text-sm">
                    Tipo de Foto
                  </label>
                  <select
                    value={currentPhoto.tipo}
                    onChange={(e) =>
                      setCurrentPhoto({ ...currentPhoto, tipo: e.target.value as PhotoType })
                    }
                    className="w-full px-4 py-2 border border-[#1A1A1A] rounded-lg bg-[#0A0A0A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A]"
                  >
                    <option value="Set">Set</option>
                    <option value="Propuesta">Propuesta</option>
                    <option value="Prueba">Prueba</option>
                  </select>
                </div>

                <div className="relative">
                  <label className="block mb-2 text-[#FAFAFA] text-sm">
                    Personaje (Código)
                  </label>
                  <input
                    type="text"
                    value={currentPhoto.personaje}
                    onChange={handlePersonajeChange}
                    onFocus={() => currentPhoto.personaje && setShowCharacterSuggestions(true)}
                    className="w-full px-4 py-2 border border-[#1A1A1A] rounded-lg bg-[#0A0A0A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A]"
                    placeholder="Ej: P001"
                  />
                  {showCharacterSuggestions && filteredCharacters.length > 0 && (
                    <div className="absolute top-full mt-1 w-full bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg shadow-lg z-10 max-h-48 overflow-y-auto">
                      {filteredCharacters.map((char) => (
                        <button
                          key={char.codigo}
                          type="button"
                          onClick={() => handleSelectCharacter(char.codigo)}
                          className="w-full px-4 py-2 text-left text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors flex items-center justify-between"
                        >
                          <span>{char.codigo}</span>
                          <span className="text-[#6B6B6B] text-sm">{char.nombre}</span>
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                <div>
                  <label className="block mb-2 text-[#FAFAFA] text-sm">
                    Descripción
                  </label>
                  <textarea
                    value={currentPhoto.descripcion}
                    onChange={(e) =>
                      setCurrentPhoto({ ...currentPhoto, descripcion: e.target.value })
                    }
                    rows={2}
                    className="w-full px-4 py-2 border border-[#1A1A1A] rounded-lg bg-[#0A0A0A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] resize-none"
                    placeholder="Descripción de la foto"
                  />
                </div>

                <div>
                  <label className="block mb-2 text-[#FAFAFA] text-sm">
                    Notas de Continuidad
                  </label>
                  <textarea
                    value={currentPhoto.notas}
                    onChange={(e) =>
                      setCurrentPhoto({ ...currentPhoto, notas: e.target.value })
                    }
                    rows={3}
                    className="w-full px-4 py-2 border border-[#1A1A1A] rounded-lg bg-[#0A0A0A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] resize-none"
                    placeholder="Detalles relevantes para continuidad: vestuario, maquillaje, props, iluminación, etc."
                  />
                </div>

                <label className="cursor-pointer bg-[#0B4F8A] text-white px-4 py-3 rounded-lg hover:bg-[#094170] transition-colors flex items-center justify-center gap-2">
                  <Upload className="w-5 h-5" />
                  Subir Foto(s)
                  <input
                    type="file"
                    accept="image/*"
                    multiple
                    onChange={handlePhotoUpload}
                    className="hidden"
                  />
                </label>
              </div>
            </div>

            {/* Photos Grid */}
            <div className="space-y-4">
              <h3 className="text-[#FAFAFA]">Fotos de Continuidad ({photos.length})</h3>
              <div className="grid grid-cols-1 gap-4 max-h-96 overflow-y-auto">
                {photos.map((photo) => (
                  <div
                    key={photo.id}
                    className="bg-[#2A2A2A] rounded-lg p-4 relative"
                  >
                    <button
                      onClick={() => handleRemovePhoto(photo.id)}
                      className="absolute top-2 right-2 p-1 bg-red-600 rounded-full hover:bg-red-700 transition-colors"
                    >
                      <X className="w-4 h-4 text-white" />
                    </button>
                    <img
                      src={photo.url}
                      alt="Continuidad"
                      className="w-full h-48 object-cover rounded-lg mb-3"
                    />
                    <div className="space-y-2">
                      <div className="flex items-center gap-2 mb-2">
                        <span
                          className="px-3 py-1 rounded-full text-xs text-white"
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
                      </div>
                      <p className="text-[#FAFAFA]">
                        <span className="text-[#6B6B6B]">Personaje:</span> {photo.personaje}
                      </p>
                      <p className="text-[#FAFAFA]">
                        <span className="text-[#6B6B6B]">Descripción:</span>{" "}
                        {photo.descripcion}
                      </p>
                      {photo.notas && (
                        <p className="text-[#FAFAFA] text-sm">
                          <span className="text-[#6B6B6B]">Notas:</span> {photo.notas}
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
