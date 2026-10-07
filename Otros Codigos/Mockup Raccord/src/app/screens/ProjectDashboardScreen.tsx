import { useState, useEffect, useRef } from "react";
import { useLocation, useNavigate } from "react-router";
import { Menu, User, Globe, Bell, LogOut } from "lucide-react";
import logo from "../../imports/Logo_Negativo.png";

const modules = [
  { name: "Guión", color: "#0B4F8A" },
  { name: "Escenas", color: "#7B5FCF" },
  { name: "Plan de Rodaje", color: "#E67E5C" },
  { name: "Desglose", color: "#6B6B6B" },
];

const mockScenesInProgress = [
  { numero: "1", nombre: "María en la cabaña", status: "En proceso" },
  { numero: "4", nombre: "Encuentro nocturno", status: "En proceso" },
];

const mockScenesPending = [
  { numero: "3", nombre: "La huida al amanecer", status: "Pendiente" },
  { numero: "5", nombre: "Amanecer en la montaña", status: "Pendiente" },
  { numero: "6", nombre: "Despedida final", status: "Pendiente" },
];

const mockNews = [
  {
    id: "1",
    title: "Cambio de locación Escena 7",
    content: "La escena 7 se moverá de la cabaña A a la cabaña B por temas de iluminación.",
    date: "2026-05-18",
  },
  {
    id: "2",
    title: "Llamado general mañana 6:00 AM",
    content: "Todo el equipo debe estar en locación a las 6:00 AM para iniciar grabación de escenas exteriores.",
    date: "2026-05-17",
  },
  {
    id: "3",
    title: "Revisión de vestuario",
    content: "Vestuario solicita revisión de continuidad para personajes principales hoy a las 3:00 PM.",
    date: "2026-05-16",
  },
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

export default function ProjectDashboardScreen() {
  const location = useLocation();
  const navigate = useNavigate();
  const projectName = location.state?.projectName || "Proyecto";
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const profileRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsMenuOpen(false);
      }
      if (profileRef.current && !profileRef.current.contains(event.target as Node)) {
        setIsProfileMenuOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleModuleClick = (moduleName: string) => {
    if (moduleName === "Guión") {
      navigate("/guiones", { state: { projectName } });
    } else if (moduleName === "Escenas") {
      navigate("/escenas", { state: { projectName } });
    } else if (moduleName === "Plan de Rodaje") {
      navigate("/plan-de-rodaje", { state: { projectName } });
    } else if (moduleName === "Desglose") {
      navigate("/desglose", { state: { projectName } });
    }
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

  const handleLanguageChange = () => {
    console.log("Cambiando idioma");
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
            <img src={logo} alt="Logo" className="h-10" />
          </div>

          {/* Profile Menu */}
          <div className="relative" ref={profileRef}>
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
                  onClick={handleLanguageChange}
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

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-8 py-8">
        {/* Project Name and Menu Button */}
        <div className="mb-8">
          <h1 className="text-[#FAFAFA] mb-4">{projectName}</h1>
          <div className="inline-block" ref={menuRef}>
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="flex items-center gap-2 px-4 py-2 bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg hover:bg-[#2A2A2A] transition-colors"
            >
              <Menu className="w-5 h-5 text-[#FAFAFA]" />
              <span className="text-[#FAFAFA]">Menú</span>
            </button>
          </div>
        </div>

        {/* Content Area - Menu and Modules Side by Side */}
        <div className="flex gap-8">
          {/* Menu Sidebar - Appears on the right when open */}
          {isMenuOpen && (
            <div className="w-64 bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg shadow-lg py-2 h-fit flex-shrink-0">
              {menuOptions.map((option) => (
                <button
                  key={option}
                  onClick={() => handleMenuOption(option)}
                  className="w-full px-4 py-3 text-left text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors"
                >
                  {option}
                </button>
              ))}
            </div>
          )}

          {/* Modules Grid - Adjusts size based on menu state */}
          <div className={`flex-1 grid gap-6 transition-all ${
            isMenuOpen
              ? "grid-cols-1 md:grid-cols-2"
              : "grid-cols-1 md:grid-cols-2 lg:grid-cols-4"
          }`}>
            {modules.map((module) => (
              <div
                key={module.name}
                className={`bg-[#1A1A1A] rounded-2xl shadow-lg border border-[#2A2A2A] flex flex-col items-center justify-center transition-all ${
                  isMenuOpen
                    ? "p-6 min-h-[220px]"
                    : "p-12 min-h-[320px]"
                }`}
              >
                <div
                  className={`rounded-full flex items-center justify-center transition-all ${
                    isMenuOpen
                      ? "w-16 h-16 mb-4"
                      : "w-24 h-24 mb-8"
                  }`}
                  style={{ backgroundColor: module.color }}
                >
                  <span className={`text-white ${isMenuOpen ? "text-2xl" : "text-4xl"}`}>📋</span>
                </div>

                <h3 className={`text-[#FAFAFA] text-center mb-4 ${
                  isMenuOpen ? "text-base" : "text-xl"
                }`}>
                  {module.name}
                </h3>

                <button
                  onClick={() => handleModuleClick(module.name)}
                  className="px-6 py-2 rounded-lg bg-[#0B4F8A] text-white hover:bg-[#094170] transition-colors"
                >
                  Ver más
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* News and Scenes Section */}
        <div className="mt-12 grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Left: News/Communications */}
          <div className="bg-[#1A1A1A] rounded-lg border border-[#2A2A2A] p-6">
            <div className="flex items-center gap-2 mb-6">
              <Bell className="w-5 h-5 text-[#0B4F8A]" />
              <h2 className="text-[#FAFAFA] text-xl">Noticias y Comunicados</h2>
            </div>
            <div className="space-y-4 max-h-96 overflow-y-auto">
              {mockNews.map((news) => (
                <div
                  key={news.id}
                  className="p-4 bg-[#2A2A2A] rounded-lg hover:bg-[#3A3A3A] transition-colors"
                >
                  <div className="flex items-start justify-between mb-2">
                    <h3 className="text-[#FAFAFA] font-medium">{news.title}</h3>
                    <span className="text-[#6B6B6B] text-xs whitespace-nowrap ml-2">
                      {news.date}
                    </span>
                  </div>
                  <p className="text-[#6B6B6B] text-sm">{news.content}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Right: Scenes in Progress and Pending */}
          <div className="space-y-6">
            {/* Scenes in Progress */}
            <div className="bg-[#1A1A1A] rounded-lg border border-[#2A2A2A] p-6">
              <h2 className="text-[#FAFAFA] text-xl mb-4">Escenas en Proceso</h2>
              <div className="space-y-3">
                {mockScenesInProgress.map((scene) => (
                  <div
                    key={scene.numero}
                    className="p-3 bg-[#2A2A2A] rounded-lg flex items-center justify-between hover:bg-[#3A3A3A] transition-colors cursor-pointer"
                    onClick={() => navigate("/escenas", { state: { projectName } })}
                  >
                    <div>
                      <p className="text-[#FAFAFA]">Escena #{scene.numero}</p>
                      <p className="text-[#6B6B6B] text-sm">{scene.nombre}</p>
                    </div>
                    <span className="px-3 py-1 rounded-full text-xs text-white bg-[#F2A341]">
                      {scene.status}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* Scenes Pending */}
            <div className="bg-[#1A1A1A] rounded-lg border border-[#2A2A2A] p-6">
              <h2 className="text-[#FAFAFA] text-xl mb-4">Escenas Pendientes</h2>
              <div className="space-y-3">
                {mockScenesPending.map((scene) => (
                  <div
                    key={scene.numero}
                    className="p-3 bg-[#2A2A2A] rounded-lg flex items-center justify-between hover:bg-[#3A3A3A] transition-colors cursor-pointer"
                    onClick={() => navigate("/escenas", { state: { projectName } })}
                  >
                    <div>
                      <p className="text-[#FAFAFA]">Escena #{scene.numero}</p>
                      <p className="text-[#6B6B6B] text-sm">{scene.nombre}</p>
                    </div>
                    <span className="px-3 py-1 rounded-full text-xs text-white bg-[#C64545]">
                      {scene.status}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Volver Button - Bottom Left */}
        <div className="mt-12">
          <button
            onClick={() => navigate(-1)}
            className="text-[#FAFAFA] hover:text-[#0B4F8A] transition-colors flex items-center gap-2"
          >
            ← Volver
          </button>
        </div>
      </main>
    </div>
  );
}
