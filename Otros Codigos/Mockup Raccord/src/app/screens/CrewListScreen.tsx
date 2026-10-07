import { useState } from "react";
import { useNavigate, useLocation } from "react-router";
import { Download, Search, Menu, User, Globe, LogOut } from "lucide-react";
import logo from "../../imports/Logo_Negativo.png";

interface Character {
  id: string;
  codigo: string;
  nombre: string;
  edad?: string;
}

const mockCharacters: Character[] = [
  { id: "1", codigo: "P001", nombre: "María", edad: "35" },
  { id: "2", codigo: "P002", nombre: "Roberto", edad: "42" },
  { id: "3", codigo: "P003", nombre: "Ana", edad: "28" },
];

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

export default function CrewListScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const projectName = location.state?.projectName || "Proyecto";
  const [characters, setCharacters] = useState<Character[]>(mockCharacters);
  const [searchTerm, setSearchTerm] = useState("");
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

  const handleExportList = () => {
    // Crear CSV
    const headers = ["Código", "Nombre del Personaje"];
    const rows = characters.map((char) => [char.codigo, char.nombre]);
    const csvContent = [
      headers.join(","),
      ...rows.map((row) => row.join(",")),
    ].join("\n");

    // Descargar archivo
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    const url = URL.createObjectURL(blob);
    link.setAttribute("href", url);
    link.setAttribute("download", `crew-list-${projectName}.csv`);
    link.style.visibility = "hidden";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const filteredCharacters = characters.filter((char) =>
    char.nombre.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-[#0A0A0A]">
      {/* Header */}
      <header className="bg-[#1A1A1A] border-b border-[#2A2A2A] px-8 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate(-1)}
              className="text-[#FAFAFA] hover:text-[#0B4F8A] transition-colors"
            >
              ← Volver
            </button>
            <img src={logo} alt="Logo" className="h-10" />
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="ml-4 p-2 hover:bg-[#2A2A2A] rounded-lg transition-colors"
            >
              <Menu className="w-5 h-5 text-[#FAFAFA]" />
            </button>
          </div>
          <h2 className="text-[#FAFAFA]">{projectName} - Crew List</h2>
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
      <main className="max-w-5xl mx-auto px-8 py-12">
        {/* Search */}
        <div className="mb-8 flex items-center gap-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-[#6B6B6B]" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Buscar personaje por nombre..."
              className="w-full pl-10 pr-4 py-3 border border-[#2A2A2A] rounded-lg bg-[#1A1A1A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A]"
            />
          </div>
        </div>

        {/* Table */}
        <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg overflow-hidden mb-8">
          <table className="w-full">
            <thead className="bg-[#2A2A2A]">
              <tr>
                <th className="px-6 py-4 text-left text-[#FAFAFA]">
                  Código
                </th>
                <th className="px-6 py-4 text-left text-[#FAFAFA]">
                  Nombre del Personaje
                </th>
              </tr>
            </thead>
            <tbody>
              {filteredCharacters.map((character) => (
                <tr
                  key={character.id}
                  className="border-t border-[#2A2A2A] hover:bg-[#2A2A2A] transition-colors"
                >
                  <td className="px-6 py-4 text-[#FAFAFA]">{character.codigo}</td>
                  <td className="px-6 py-4 text-[#FAFAFA]">{character.nombre}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Export Button */}
        <button
          onClick={handleExportList}
          className="flex items-center gap-3 px-6 py-3 bg-[#0B4F8A] text-white rounded-lg hover:bg-[#094170] transition-colors"
        >
          <Download className="w-5 h-5" />
          Exportar Lista
        </button>
      </main>
    </div>
  );
}
