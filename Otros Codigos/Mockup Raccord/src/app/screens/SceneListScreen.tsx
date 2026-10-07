import { useState } from "react";
import { useNavigate, useLocation } from "react-router";
import { Plus, Filter, Menu, User, Globe, Edit2, Eye, ArrowUpDown, LogOut } from "lucide-react";
import logo from "../../imports/Logo_Negativo.png";

type SceneStatus = "Pendiente" | "En proceso" | "Finalizada";

type SortOption = "numeroEscena" | "diaDramatico" | "fechaGrabacion" | "ciudad";
type SortOrder = "asc" | "desc";

interface Scene {
  id: string;
  numeroEscena: string;
  encabezado: string;
  diaDramatico: string;
  fechaGrabacion: string;
  ciudad: string;
  status: SceneStatus;
}

const mockScenes: Scene[] = [
  {
    id: "1",
    numeroEscena: "1",
    encabezado: "María en la cabaña",
    diaDramatico: "Día 1",
    fechaGrabacion: "2026-06-15",
    ciudad: "Bogotá",
    status: "Finalizada",
  },
  {
    id: "2",
    numeroEscena: "2",
    encabezado: "Sombras en el bosque",
    diaDramatico: "Día 1",
    fechaGrabacion: "2026-06-15",
    ciudad: "Bogotá",
    status: "En proceso",
  },
  {
    id: "3",
    numeroEscena: "3",
    encabezado: "La huida al amanecer",
    diaDramatico: "Día 2",
    fechaGrabacion: "2026-06-16",
    ciudad: "Bogotá",
    status: "Pendiente",
  },
];

const statusColors: Record<SceneStatus, string> = {
  Pendiente: "#C64545",
  "En proceso": "#F2A341",
  Finalizada: "#3d9970",
};

const allStatuses: SceneStatus[] = ["Pendiente", "En proceso", "Finalizada"];

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

export default function SceneListScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const projectName = location.state?.projectName || "Proyecto";
  const [scenes, setScenes] = useState<Scene[]>(mockScenes);
  const [filterStatus, setFilterStatus] = useState<SceneStatus | "Todos">("Todos");
  const [sortBy, setSortBy] = useState<SortOption>("numeroEscena");
  const [sortOrder, setSortOrder] = useState<SortOrder>("asc");
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

  const handleCreateScene = () => {
    navigate("/crear-escena", { state: { projectName } });
  };

  const handleEditScene = (scene: Scene) => {
    navigate("/escena-detalle", { state: { scene, projectName } });
  };

  const handleViewPhotos = (scene: Scene) => {
    navigate("/escena-fotos", { state: { scene, projectName } });
  };

  const toggleSortOrder = () => {
    setSortOrder(sortOrder === "asc" ? "desc" : "asc");
  };

  const filteredScenes =
    filterStatus === "Todos"
      ? scenes
      : scenes.filter((scene) => scene.status === filterStatus);

  const sortedScenes = [...filteredScenes].sort((a, b) => {
    let comparison = 0;
    if (sortBy === "numeroEscena") {
      comparison = parseInt(a.numeroEscena) - parseInt(b.numeroEscena);
    } else if (sortBy === "diaDramatico") {
      comparison = a.diaDramatico.localeCompare(b.diaDramatico);
    } else if (sortBy === "fechaGrabacion") {
      comparison = a.fechaGrabacion.localeCompare(b.fechaGrabacion);
    } else if (sortBy === "ciudad") {
      comparison = a.ciudad.localeCompare(b.ciudad);
    }
    return sortOrder === "asc" ? comparison : -comparison;
  });

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
          <h2 className="text-[#FAFAFA]">{projectName} - Escenas</h2>
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
        {/* Filter and Sort Section */}
        <div className="mb-8 flex items-center gap-6">
          <div className="flex items-center gap-4">
            <Filter className="w-5 h-5 text-[#FAFAFA]" />
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value as SceneStatus | "Todos")}
              className="px-4 py-2 border border-[#2A2A2A] rounded-lg bg-[#1A1A1A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A]"
            >
              <option value="Todos">Todos los estados</option>
              {allStatuses.map((status) => (
                <option key={status} value={status}>
                  {status}
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-center gap-4">
            <span className="text-[#FAFAFA]">Ordenar por:</span>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as SortOption)}
              className="px-4 py-2 border border-[#2A2A2A] rounded-lg bg-[#1A1A1A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A]"
            >
              <option value="numeroEscena">Número de Escena</option>
              <option value="diaDramatico">Día Dramático</option>
              <option value="fechaGrabacion">Fecha de Grabación</option>
              <option value="ciudad">Ciudad</option>
            </select>
            <button
              onClick={toggleSortOrder}
              className="p-2 border border-[#2A2A2A] rounded-lg bg-[#1A1A1A] text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors"
              title={sortOrder === "asc" ? "Ascendente" : "Descendente"}
            >
              <ArrowUpDown className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Scenes List */}
        <div className="space-y-4 mb-8">
          {sortedScenes.map((scene) => (
            <div
              key={scene.id}
              className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg p-6 hover:border-[#0B4F8A] transition-colors"
            >
              <div className="flex items-center justify-between">
                <div className="flex-1 grid grid-cols-4 gap-4">
                  <div>
                    <p className="text-[#6B6B6B] text-sm mb-1">Escena</p>
                    <p className="text-[#FAFAFA] text-lg">#{scene.numeroEscena}</p>
                  </div>
                  <div>
                    <p className="text-[#6B6B6B] text-sm mb-1">Encabezado</p>
                    <p className="text-[#FAFAFA]">{scene.encabezado}</p>
                  </div>
                  <div>
                    <p className="text-[#6B6B6B] text-sm mb-1">Día Dramático</p>
                    <p className="text-[#FAFAFA]">{scene.diaDramatico}</p>
                  </div>
                  <div>
                    <p className="text-[#6B6B6B] text-sm mb-1">Estado</p>
                    <span
                      className="inline-block px-3 py-1 rounded-full text-sm text-white"
                      style={{ backgroundColor: statusColors[scene.status] }}
                    >
                      {scene.status}
                    </span>
                  </div>
                </div>
                <div className="flex gap-2 ml-4">
                  <button
                    onClick={() => handleViewPhotos(scene)}
                    className="p-2 text-[#FAFAFA] hover:bg-[#2A2A2A] rounded-lg transition-colors"
                    title="Ver fotos"
                  >
                    <Eye className="w-5 h-5" />
                  </button>
                  <button
                    onClick={() => handleEditScene(scene)}
                    className="p-2 text-[#FAFAFA] hover:bg-[#2A2A2A] rounded-lg transition-colors"
                    title="Editar"
                  >
                    <Edit2 className="w-5 h-5" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Create Button */}
        <button
          onClick={handleCreateScene}
          className="flex items-center gap-3 px-6 py-3 bg-[#0B4F8A] text-white rounded-lg hover:bg-[#094170] transition-colors"
        >
          <Plus className="w-5 h-5" />
          Crear Escena
        </button>
      </main>
    </div>
  );
}
