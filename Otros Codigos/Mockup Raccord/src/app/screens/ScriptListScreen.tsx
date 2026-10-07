import { useState, useRef, useEffect } from "react";
import { useNavigate, useLocation } from "react-router";
import { Plus, Filter, Edit2, X, Check, Menu, User, Globe, LogOut } from "lucide-react";
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

type ScriptStatus = "Revision" | "Aprobado" | "En rodaje" | "Archivado";

interface Script {
  id: string;
  name: string;
  status: ScriptStatus;
  version: string;
}

const mockScripts: Script[] = [
  {
    id: "1",
    name: "El Último Amanecer - Versión Final",
    status: "Aprobado",
    version: "v3.2",
  },
  {
    id: "2",
    name: "El Último Amanecer - Borrador",
    status: "Revision",
    version: "v2.1",
  },
];

const statusColors: Record<ScriptStatus, string> = {
  Revision: "#E67E5C",
  Aprobado: "#4CAF50",
  "En rodaje": "#0B4F8A",
  Archivado: "#6B6B6B",
};

const allStatuses: ScriptStatus[] = ["Revision", "Aprobado", "En rodaje", "Archivado"];

export default function ScriptListScreen() {
  const navigate = useNavigate();
  const location = useLocation();
  const projectName = location.state?.projectName || "Proyecto";
  const [scripts, setScripts] = useState<Script[]>(mockScripts);
  const [filterStatus, setFilterStatus] = useState<ScriptStatus | "Todos">("Todos");
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editForm, setEditForm] = useState<Script | null>(null);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);

  const handleScriptClick = (script: Script) => {
    navigate("/guion-detalle", { state: { script, projectName } });
  };

  const handleUploadScript = () => {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = ".pdf,.doc,.docx,.txt";
    input.onchange = (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (file) {
        console.log("Archivo subido:", file.name);
        // Aquí procesarías el archivo
      }
    };
    input.click();
  };

  const handleEditClick = (script: Script, e: React.MouseEvent) => {
    e.stopPropagation();
    setEditingId(script.id);
    setEditForm({ ...script });
  };

  const handleCancelEdit = (e: React.MouseEvent) => {
    e.stopPropagation();
    setEditingId(null);
    setEditForm(null);
  };

  const handleSaveEdit = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (editForm) {
      setScripts(scripts.map((s) => (s.id === editForm.id ? editForm : s)));
      setEditingId(null);
      setEditForm(null);
    }
  };

  const handleEditFormChange = (
    field: keyof Script,
    value: string,
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    e.stopPropagation();
    if (editForm) {
      setEditForm({ ...editForm, [field]: value });
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

  const handleLogout = () => {
    navigate("/");
    setIsProfileMenuOpen(false);
  };

  const filteredScripts =
    filterStatus === "Todos"
      ? scripts
      : scripts.filter((script) => script.status === filterStatus);

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
          <h2 className="text-[#FAFAFA]">{projectName} - Guiones</h2>
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
        {/* Filter Section */}
        <div className="mb-8 flex items-center gap-4">
          <Filter className="w-5 h-5 text-[#FAFAFA]" />
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value as ScriptStatus | "Todos")}
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

        {/* Scripts List */}
        <div className="space-y-4 mb-8">
          {filteredScripts.map((script) => (
            <div
              key={script.id}
              className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg p-6 hover:border-[#0B4F8A] transition-colors"
            >
              {editingId === script.id && editForm ? (
                <div className="space-y-4" onClick={(e) => e.stopPropagation()}>
                  <div>
                    <label className="block mb-2 text-[#FAFAFA] text-sm">
                      Nombre del Guión
                    </label>
                    <input
                      type="text"
                      value={editForm.name}
                      onChange={(e) => handleEditFormChange("name", e.target.value, e)}
                      className="w-full px-4 py-2 border border-[#2A2A2A] rounded-lg bg-[#0A0A0A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A]"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block mb-2 text-[#FAFAFA] text-sm">
                        Estado
                      </label>
                      <select
                        value={editForm.status}
                        onChange={(e) =>
                          handleEditFormChange("status", e.target.value, e)
                        }
                        className="w-full px-4 py-2 border border-[#2A2A2A] rounded-lg bg-[#0A0A0A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A]"
                      >
                        {allStatuses.map((status) => (
                          <option key={status} value={status}>
                            {status}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label className="block mb-2 text-[#FAFAFA] text-sm">
                        Versión
                      </label>
                      <input
                        type="text"
                        value={editForm.version}
                        onChange={(e) =>
                          handleEditFormChange("version", e.target.value, e)
                        }
                        className="w-full px-4 py-2 border border-[#2A2A2A] rounded-lg bg-[#0A0A0A] text-[#FAFAFA] focus:outline-none focus:ring-2 focus:ring-[#0B4F8A]"
                      />
                    </div>
                  </div>
                  <div className="flex gap-2 justify-end">
                    <button
                      onClick={handleCancelEdit}
                      className="flex items-center gap-2 px-4 py-2 bg-[#2A2A2A] text-[#FAFAFA] rounded-lg hover:bg-[#3A3A3A] transition-colors"
                    >
                      <X className="w-4 h-4" />
                      Cancelar
                    </button>
                    <button
                      onClick={handleSaveEdit}
                      className="flex items-center gap-2 px-4 py-2 bg-[#0B4F8A] text-white rounded-lg hover:bg-[#094170] transition-colors"
                    >
                      <Check className="w-4 h-4" />
                      Guardar
                    </button>
                  </div>
                </div>
              ) : (
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <button
                      onClick={() => handleScriptClick(script)}
                      className="text-[#FAFAFA] hover:text-[#0B4F8A] transition-colors text-left"
                    >
                      <h3 className="text-lg mb-2">{script.name}</h3>
                    </button>
                    <div className="flex items-center gap-4">
                      <span
                        className="px-3 py-1 rounded-full text-sm text-white"
                        style={{ backgroundColor: statusColors[script.status] }}
                      >
                        {script.status}
                      </span>
                      <span className="text-[#6B6B6B]">Versión: {script.version}</span>
                    </div>
                  </div>
                  <button
                    onClick={(e) => handleEditClick(script, e)}
                    className="ml-4 p-2 text-[#FAFAFA] hover:bg-[#2A2A2A] rounded-lg transition-colors"
                  >
                    <Edit2 className="w-5 h-5" />
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Upload Button */}
        <button
          onClick={handleUploadScript}
          className="flex items-center gap-3 px-6 py-3 bg-[#0B4F8A] text-white rounded-lg hover:bg-[#094170] transition-colors"
        >
          <Plus className="w-5 h-5" />
          Subir Guión
        </button>
      </main>
    </div>
  );
}
