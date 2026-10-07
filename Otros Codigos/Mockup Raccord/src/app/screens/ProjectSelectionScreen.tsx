import { useState } from "react";
import { useNavigate } from "react-router";
import { FolderOpen, Plus, ChevronRight, X, Film, Clapperboard } from "lucide-react";
import logo from "../../imports/Logo_Negativo.png";

const availableProjects = [
  { id: 1, name: "El Último Horizonte", format: "Largometraje", genre: "Drama", director: "Ana Martínez" },
  { id: 2, name: "Código Rojo", format: "Serie", genre: "Thriller", director: "Carlos Vélez" },
  { id: 3, name: "Memorias del Sur", format: "Documental", genre: "Histórico", director: "Luisa Peralta" },
  { id: 4, name: "Sombras Blancas", format: "Cortometraje", genre: "Terror", director: "Marcos Díaz" },
];

const formatOptions = [
  "serie", "miniserie", "pelicula", "largometraje", "mediometraje", "cortometraje",
  "documental", "spot publicitario", "video musical", "video corporativo",
  "video educativo", "micro-formato", "mockumentary",
];

const genreOptions = [
  "accion", "comedia", "aventura", "drama", "terror", "ciencia ficcion",
  "fantasia", "suspenso", "musical", "western", "belico", "romance",
  "crimen", "misterio", "animacion", "biopic", "documental", "video",
  "artes marciales", "thriller", "historico", "epoca", "familiar",
  "deportivo", "horror", "paranormal", "otro",
];

interface CreateProjectForm {
  projectName: string;
  format: string;
  genre: string;
  synopsis: string;
  director: string;
}

export default function ProjectSelectionScreen() {
  const [showProjectList, setShowProjectList] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [hoveredProject, setHoveredProject] = useState<number | null>(null);
  const [formData, setFormData] = useState<CreateProjectForm>({
    projectName: "",
    format: "",
    genre: "",
    synopsis: "",
    director: "",
  });
  const navigate = useNavigate();

  const handleSelectProject = (projectName: string) => {
    navigate("/proyecto-dashboard", { state: { projectName } });
  };

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleCreateProject = (e: React.FormEvent) => {
    e.preventDefault();
    const name = formData.projectName.trim() || "Nuevo Proyecto";
    setShowCreateModal(false);
    navigate("/proyecto-dashboard", { state: { projectName: name } });
  };

  return (
    <div className="min-h-screen bg-[#0A0A0A]">
      {/* Header */}
      <header className="bg-[#1A1A1A] border-b border-[#2A2A2A] px-8 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-center">
          <img src={logo} alt="Logo" className="h-12" />
        </div>
      </header>

      {/* Content */}
      <main className="max-w-3xl mx-auto px-6 py-16">
        {/* Page heading */}
        <div className="text-center mb-12">
          <Clapperboard className="w-10 h-10 text-[#0B4F8A] mx-auto mb-4 opacity-80" />
          <h1 className="text-[#FAFAFA] text-2xl font-semibold tracking-wide mb-2">
            Gestión de Proyectos
          </h1>
          <p className="text-[#6B6B6B] text-sm">
            Accede a un proyecto existente o inicia uno nuevo en el sistema.
          </p>
        </div>

        {/* Two action buttons */}
        <div className="grid grid-cols-2 gap-5 mb-8">
          {/* Escoger proyecto */}
          <button
            onClick={() => {
              setShowProjectList((prev) => !prev);
              setShowCreateModal(false);
            }}
            className={`group relative flex flex-col items-center gap-4 py-10 px-6 rounded-xl border-2 transition-all duration-200 ${
              showProjectList
                ? "bg-[#0B4F8A]/15 border-[#0B4F8A] shadow-lg shadow-[#0B4F8A]/10"
                : "bg-[#1A1A1A] border-[#2A2A2A] hover:border-[#0B4F8A]/60 hover:bg-[#0B4F8A]/5"
            }`}
          >
            <div
              className={`w-16 h-16 rounded-full flex items-center justify-center transition-all ${
                showProjectList
                  ? "bg-[#0B4F8A]"
                  : "bg-[#2A2A2A] group-hover:bg-[#0B4F8A]/20"
              }`}
            >
              <FolderOpen
                className={`w-7 h-7 transition-colors ${
                  showProjectList ? "text-white" : "text-[#6B6B6B] group-hover:text-[#0B4F8A]"
                }`}
              />
            </div>
            <div className="text-center">
              <span
                className={`block font-semibold text-base tracking-wide transition-colors ${
                  showProjectList ? "text-[#FAFAFA]" : "text-[#FAFAFA]"
                }`}
              >
                Escoger Proyecto
              </span>
              <span className="block text-xs text-[#6B6B6B] mt-1">
                Acceder a un proyecto existente
              </span>
            </div>
            {showProjectList && (
              <span className="absolute top-3 right-3 w-2 h-2 rounded-full bg-[#0B4F8A]" />
            )}
          </button>

          {/* Crear proyecto */}
          <button
            onClick={() => {
              setShowCreateModal(true);
              setShowProjectList(false);
            }}
            className="group relative flex flex-col items-center gap-4 py-10 px-6 rounded-xl border-2 border-[#2A2A2A] bg-[#1A1A1A] hover:border-[#7B5FCF]/60 hover:bg-[#7B5FCF]/5 transition-all duration-200"
          >
            <div className="w-16 h-16 rounded-full bg-[#2A2A2A] group-hover:bg-[#7B5FCF]/20 flex items-center justify-center transition-all">
              <Plus className="w-7 h-7 text-[#6B6B6B] group-hover:text-[#7B5FCF] transition-colors" />
            </div>
            <div className="text-center">
              <span className="block font-semibold text-base tracking-wide text-[#FAFAFA]">
                Crear Proyecto
              </span>
              <span className="block text-xs text-[#6B6B6B] mt-1">
                Registrar un nuevo proyecto
              </span>
            </div>
          </button>
        </div>

        {/* Project List (expands below) */}
        {showProjectList && (
          <div className="bg-[#1A1A1A] border border-[#2A2A2A] rounded-xl overflow-hidden">
            <div className="px-6 py-4 border-b border-[#2A2A2A] flex items-center gap-2">
              <Film className="w-4 h-4 text-[#0B4F8A]" />
              <span className="text-[#FAFAFA] text-sm font-semibold tracking-wide">
                Proyectos disponibles
              </span>
              <span className="ml-auto text-[#6B6B6B] text-xs">
                {availableProjects.length} proyectos
              </span>
            </div>

            <ul className="divide-y divide-[#2A2A2A]">
              {availableProjects.map((project) => (
                <li key={project.id}>
                  <button
                    onClick={() => handleSelectProject(project.name)}
                    onMouseEnter={() => setHoveredProject(project.id)}
                    onMouseLeave={() => setHoveredProject(null)}
                    className="w-full flex items-center gap-4 px-6 py-4 hover:bg-[#0B4F8A]/8 transition-colors text-left group"
                  >
                    <div className="w-10 h-10 rounded-lg bg-[#0B4F8A]/15 border border-[#0B4F8A]/20 flex items-center justify-center flex-shrink-0 group-hover:bg-[#0B4F8A]/25 transition-colors">
                      <Clapperboard className="w-4 h-4 text-[#0B4F8A]" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-[#FAFAFA] font-medium text-sm truncate">
                        {project.name}
                      </p>
                      <p className="text-[#6B6B6B] text-xs mt-0.5">
                        {project.format} &middot; {project.genre} &middot; Dir. {project.director}
                      </p>
                    </div>
                    <ChevronRight
                      className={`w-4 h-4 flex-shrink-0 transition-all ${
                        hoveredProject === project.id
                          ? "text-[#0B4F8A] translate-x-0.5"
                          : "text-[#2A2A2A]"
                      }`}
                    />
                  </button>
                </li>
              ))}
            </ul>
          </div>
        )}
      </main>

      {/* Create Project Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Overlay */}
          <div
            className="absolute inset-0 bg-black/70 backdrop-blur-sm"
            onClick={() => setShowCreateModal(false)}
          />

          {/* Modal */}
          <div className="relative w-full max-w-lg bg-[#1A1A1A] rounded-xl border border-[#2A2A2A] shadow-2xl overflow-hidden max-h-[90vh] flex flex-col">
            {/* Modal Header */}
            <div className="bg-gradient-to-r from-[#7B5FCF] to-[#0B4F8A] px-7 py-5 flex-shrink-0">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-white/60 text-xs font-semibold tracking-widest uppercase mb-1">
                    Nuevo registro
                  </p>
                  <h2 className="text-white text-lg font-semibold tracking-wide">
                    Crear Proyecto
                  </h2>
                </div>
                <button
                  onClick={() => setShowCreateModal(false)}
                  className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors"
                >
                  <X className="w-4 h-4 text-white" />
                </button>
              </div>
            </div>

            {/* Modal Body */}
            <div className="overflow-y-auto flex-1 p-7">
              <form onSubmit={handleCreateProject} className="space-y-5" id="create-project-form">
                <div>
                  <label className="block mb-1.5 text-[#FAFAFA] text-sm font-medium">
                    Nombre del Proyecto
                  </label>
                  <input
                    type="text"
                    name="projectName"
                    value={formData.projectName}
                    onChange={handleChange}
                    className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#7B5FCF] bg-[#0A0A0A] text-[#FAFAFA] placeholder:text-[#4A4A4A] text-sm"
                    placeholder="Nombre de la serie, película u otro proyecto audiovisual"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block mb-1.5 text-[#FAFAFA] text-sm font-medium">
                      Formato
                    </label>
                    <select
                      name="format"
                      value={formData.format}
                      onChange={handleChange}
                      className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#7B5FCF] bg-[#0A0A0A] text-[#FAFAFA] text-sm"
                    >
                      <option value="">Selecciona formato</option>
                      {formatOptions.map((f) => (
                        <option key={f} value={f}>
                          {f.charAt(0).toUpperCase() + f.slice(1)}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block mb-1.5 text-[#FAFAFA] text-sm font-medium">
                      Género
                    </label>
                    <select
                      name="genre"
                      value={formData.genre}
                      onChange={handleChange}
                      className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#7B5FCF] bg-[#0A0A0A] text-[#FAFAFA] text-sm"
                    >
                      <option value="">Selecciona género</option>
                      {genreOptions.map((g) => (
                        <option key={g} value={g}>
                          {g.charAt(0).toUpperCase() + g.slice(1)}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block mb-1.5 text-[#FAFAFA] text-sm font-medium">
                    Sinopsis
                  </label>
                  <textarea
                    name="synopsis"
                    value={formData.synopsis}
                    onChange={handleChange}
                    rows={3}
                    className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#7B5FCF] bg-[#0A0A0A] text-[#FAFAFA] placeholder:text-[#4A4A4A] resize-none text-sm"
                    placeholder="Detalle de lo que trata el producto audiovisual"
                  />
                </div>

                <div>
                  <label className="block mb-1.5 text-[#FAFAFA] text-sm font-medium">
                    Director
                  </label>
                  <input
                    type="text"
                    name="director"
                    value={formData.director}
                    onChange={handleChange}
                    className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#7B5FCF] bg-[#0A0A0A] text-[#FAFAFA] placeholder:text-[#4A4A4A] text-sm"
                    placeholder="Director o directores del producto audiovisual"
                  />
                </div>
              </form>
            </div>

            {/* Modal Footer */}
            <div className="px-7 py-5 border-t border-[#2A2A2A] bg-[#0A0A0A] flex items-center justify-end gap-3 flex-shrink-0">
              <button
                type="button"
                onClick={() => setShowCreateModal(false)}
                className="px-6 py-2.5 rounded-lg border border-[#2A2A2A] text-[#6B6B6B] hover:text-[#FAFAFA] hover:border-[#6B6B6B] text-sm font-medium transition-all"
              >
                Cancelar
              </button>
              <button
                type="submit"
                form="create-project-form"
                className="px-8 py-2.5 rounded-lg bg-[#7B5FCF] text-white hover:bg-[#6a4eb8] text-sm font-semibold tracking-wide transition-all shadow-lg shadow-[#7B5FCF]/20"
              >
                Crear Proyecto
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
