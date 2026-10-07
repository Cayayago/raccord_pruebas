import { useState, useRef } from "react";
import { useNavigate, useLocation } from "react-router";
import { Download, ArrowLeft, Menu, User, Globe, LogOut } from "lucide-react";
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

const mockScriptContent = `EL ÚLTIMO AMANECER
Cortometraje
Versión 3.2

INT. CABAÑA - NOCHE

La habitación está apenas iluminada por una vela parpadeante. MARÍA (35), con el rostro marcado por la preocupación, mira por la ventana hacia el bosque oscuro.

MARÍA
(susurrando)
Ya vienen. Puedo sentirlo.

Se acerca a la mesa donde descansa un viejo mapa. Sus dedos trazan una ruta marcada en tinta roja.

EXT. BOSQUE - NOCHE

Sombras se mueven entre los árboles. El sonido de ramas quebrándose rompe el silencio de la noche.

INT. CABAÑA - NOCHE

María toma una mochila y comienza a guardar provisiones apresuradamente. Se detiene al escuchar un ruido afuera.

MARÍA
(para sí misma)
Es ahora o nunca.

Apaga la vela. La oscuridad envuelve la cabaña.

EXT. CABAÑA - AMANECER

Los primeros rayos del sol iluminan la cabaña abandonada. La puerta se balancea suavemente con el viento. María ha desaparecido, dejando solo huellas que se pierden en el horizonte.

FADE OUT.`;

export default function ScriptViewScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const { script, projectName } = location.state || {};
  const [selectedText, setSelectedText] = useState("");
  const [menuPosition, setMenuPosition] = useState<{ x: number; y: number } | null>(null);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  const scriptRef = useRef<HTMLDivElement>(null);

  const handleTextSelection = (e: React.MouseEvent) => {
    e.preventDefault();
    const selection = window.getSelection();
    const text = selection?.toString().trim();

    if (text && text.length > 0) {
      setSelectedText(text);
      setMenuPosition({ x: e.clientX, y: e.clientY });
    } else {
      setMenuPosition(null);
    }
  };

  const handleCreateScene = () => {
    navigate("/crear-escena", {
      state: {
        selectedText,
        scriptName: script?.name,
        projectName,
      },
    });
  };

  const handleCreateNote = () => {
    console.log("Crear nota con texto:", selectedText);
    setMenuPosition(null);
  };

  const handleDownload = () => {
    console.log("Descargando guión:", script?.name);
    // Aquí implementarías la descarga real del guión
  };

  const handleClickOutside = () => {
    setMenuPosition(null);
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
    <div className="min-h-screen bg-[#0A0A0A]" onClick={handleClickOutside}>
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
          <h2 className="text-[#FAFAFA]">{script?.name || "Guión"}</h2>
          <div className="flex items-center gap-4">
            <button
              onClick={handleDownload}
              className="flex items-center gap-2 px-4 py-2 bg-[#0B4F8A] text-white rounded-lg hover:bg-[#094170] transition-colors"
            >
              <Download className="w-4 h-4" />
              Descargar
            </button>
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
        <div
          ref={scriptRef}
          onContextMenu={handleTextSelection}
          className="bg-white border border-[#2A2A2A] rounded-lg p-12 min-h-[600px]"
        >
          <pre className="text-[#0A0A0A] whitespace-pre-wrap leading-relaxed" style={{ fontFamily: "'Courier Prime', monospace" }}>
            {mockScriptContent}
          </pre>
        </div>

        {/* Context Menu */}
        {menuPosition && (
          <div
            className="fixed bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg shadow-lg py-2 z-50"
            style={{ top: menuPosition.y, left: menuPosition.x }}
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={handleCreateScene}
              className="w-full px-4 py-2 text-left text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors whitespace-nowrap"
            >
              Crear Escena
            </button>
            <button
              onClick={() => {
                navigate("/crear-personaje", { state: { projectName } });
                setMenuPosition(null);
              }}
              className="w-full px-4 py-2 text-left text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors whitespace-nowrap"
            >
              Crear Personaje
            </button>
            <button
              onClick={handleCreateNote}
              className="w-full px-4 py-2 text-left text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors whitespace-nowrap"
            >
              Crear Nota
            </button>
          </div>
        )}
      </main>
    </div>
  );
}
