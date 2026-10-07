import { useState } from "react";
import { useNavigate, useLocation } from "react-router";
import { ArrowLeft, Menu, User, Globe, Plus, X, LogOut } from "lucide-react";
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

const vistaOptions = ["INT", "EXT", "INT/EXT", "EXT/INT"];
const momentoOptions = ["Dia", "Noche", "Amanecer", "Atardecer"];

// Mock characters - esto debería venir de un estado global o API
const mockCharacters = [
  { codigo: "P001", nombre: "María" },
  { codigo: "P002", nombre: "Roberto" },
  { codigo: "P003", nombre: "Ana" },
];

export default function CreateSceneScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const { selectedText, scriptName, projectName } = location.state || {};

  const [formData, setFormData] = useState({
    numeroEscena: "",
    encabezado: "",
    descripcion: selectedText || "",
    vista: "",
    momento: "",
    ciudad: "",
    fechaGrabacion: "",
    diaDramatico: "",
  });
  const [personajes, setPersonajes] = useState<string[]>([]);
  const [currentPersonaje, setCurrentPersonaje] = useState("");
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  const [showCharacterSuggestions, setShowCharacterSuggestions] = useState(false);
  const [filteredCharacters, setFilteredCharacters] = useState(mockCharacters);

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value,
    });
  };

  const handlePersonajeInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setCurrentPersonaje(value);

    const filtered = mockCharacters.filter(
      (char) =>
        char.codigo.toLowerCase().includes(value.toLowerCase()) ||
        char.nombre.toLowerCase().includes(value.toLowerCase())
    );
    setFilteredCharacters(filtered);
    setShowCharacterSuggestions(value.length > 0);
  };

  const handleSelectCharacter = (codigo: string) => {
    if (!personajes.includes(codigo)) {
      setPersonajes([...personajes, codigo]);
    }
    setCurrentPersonaje("");
    setShowCharacterSuggestions(false);
  };

  const handleRemovePersonaje = (codigo: string) => {
    setPersonajes(personajes.filter((p) => p !== codigo));
  };

  const handleCreateCharacterQuick = () => {
    navigate("/crear-personaje", { state: { projectName, returnTo: "/crear-escena" } });
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Escena guardada:", formData);
    navigate(-1);
  };

  const handleSaveAndCreateAnother = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Escena guardada:", formData);
    // Limpiar el formulario para crear otra
    setFormData({
      numeroEscena: "",
      encabezado: "",
      descripcion: "",
      vista: "",
      momento: "",
      ciudad: "",
      fechaGrabacion: "",
      diaDramatico: "",
    });
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
      <main className="max-w-4xl mx-auto px-8 py-12">
        <div className="bg-[#1A1A1A] rounded-lg shadow-lg border border-[#2A2A2A] p-8">
          <h1 className="text-[#FAFAFA] mb-8">Nueva Escena</h1>

          {selectedText && (
            <div className="mb-6 p-4 bg-[#2A2A2A] rounded-lg border border-[#0B4F8A]">
              <p className="text-[#6B6B6B] text-sm mb-2">Texto seleccionado del guión:</p>
              <p className="text-[#FAFAFA] italic">"{selectedText}"</p>
            </div>
          )}

          <form className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block mb-2 text-[#FAFAFA]">
                  Escena (Número)
                </label>
                <input
                  type="text"
                  name="numeroEscena"
                  value={formData.numeroEscena}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                  placeholder="Ej: 1, 2A, 3B"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">
                  Encabezado (Título de la escena)
                </label>
                <input
                  type="text"
                  name="encabezado"
                  value={formData.encabezado}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                  placeholder="Título de la escena"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block mb-2 text-[#FAFAFA]">
                  Descripción
                </label>
                <textarea
                  name="descripcion"
                  value={formData.descripcion}
                  onChange={handleChange}
                  rows={4}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA] resize-none"
                  placeholder="Descripción de la escena"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">Vista</label>
                <select
                  name="vista"
                  value={formData.vista}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                >
                  <option value="">Seleccione vista</option>
                  {vistaOptions.map((vista) => (
                    <option key={vista} value={vista}>
                      {vista}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">Momento</label>
                <select
                  name="momento"
                  value={formData.momento}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                >
                  <option value="">Seleccione momento</option>
                  {momentoOptions.map((momento) => (
                    <option key={momento} value={momento}>
                      {momento}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">Ciudad</label>
                <input
                  type="text"
                  name="ciudad"
                  value={formData.ciudad}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                  placeholder="Ciudad donde se grabará"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">
                  Fecha de Grabación
                </label>
                <input
                  type="date"
                  name="fechaGrabacion"
                  value={formData.fechaGrabacion}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                />
              </div>

              <div>
                <label className="block mb-2 text-[#FAFAFA]">
                  Día Dramático
                </label>
                <input
                  type="text"
                  name="diaDramatico"
                  value={formData.diaDramatico}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                  placeholder="Día dramático de la escena"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block mb-2 text-[#FAFAFA]">
                  Personajes
                </label>

                {/* Selected Characters */}
                {personajes.length > 0 && (
                  <div className="flex flex-wrap gap-2 mb-3">
                    {personajes.map((codigo) => {
                      const char = mockCharacters.find((c) => c.codigo === codigo);
                      return (
                        <span
                          key={codigo}
                          className="inline-flex items-center gap-2 px-3 py-1 bg-[#0B4F8A] text-white rounded-full"
                        >
                          {codigo} - {char?.nombre}
                          <button
                            type="button"
                            onClick={() => handleRemovePersonaje(codigo)}
                            className="hover:bg-[#094170] rounded-full p-1"
                          >
                            <X className="w-3 h-3" />
                          </button>
                        </span>
                      );
                    })}
                  </div>
                )}

                {/* Add Character Input */}
                <div className="flex gap-2">
                  <div className="flex-1 relative">
                    <input
                      type="text"
                      value={currentPersonaje}
                      onChange={handlePersonajeInputChange}
                      onFocus={() => currentPersonaje && setShowCharacterSuggestions(true)}
                      className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                      placeholder="Agregar personaje (Ej: P001)"
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
                  <button
                    type="button"
                    onClick={handleCreateCharacterQuick}
                    className="px-4 py-3 bg-[#7B5FCF] text-white rounded-lg hover:bg-[#6B4FBF] transition-colors flex items-center justify-center"
                    title="Crear nuevo personaje"
                  >
                    <Plus className="w-5 h-5" />
                  </button>
                </div>
              </div>
            </div>

            <div className="flex gap-4 justify-end pt-4">
              <button
                onClick={handleSave}
                className="px-6 py-3 bg-[#0B4F8A] text-white rounded-lg hover:bg-[#094170] transition-colors"
              >
                Guardar
              </button>
              <button
                onClick={handleSaveAndCreateAnother}
                className="px-6 py-3 bg-[#7B5FCF] text-white rounded-lg hover:bg-[#6B4FBF] transition-colors"
              >
                Guardar y Crear
              </button>
            </div>
          </form>
        </div>
      </main>
    </div>
  );
}
