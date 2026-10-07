import { useState } from "react";
import { useNavigate } from "react-router";
import logo from "../../imports/Logo_Negativo.png";

const formatOptions = [
  "serie",
  "miniserie",
  "pelicula",
  "largometraje",
  "mediometraje",
  "cortometraje",
  "documental",
  "spot publicitario",
  "video musical",
  "video corporativo",
  "video educativo",
  "micro-formato",
  "mockumentary",
];

const genreOptions = [
  "accion",
  "comedia",
  "aventura",
  "drama",
  "terror",
  "ciencia ficcion",
  "fantasia",
  "suspenso",
  "musical",
  "western",
  "belico",
  "romance",
  "crimen",
  "misterio",
  "animacion",
  "biopic",
  "documental",
  "video",
  "artes marciales",
  "thriller",
  "historico",
  "epoca",
  "familiar",
  "deportivo",
  "horror",
  "paranormal",
  "otro",
];

export default function ProjectRegistrationScreen() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    projectName: "",
    format: "",
    genre: "",
    synopsis: "",
    director: "",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Proyecto registrado:", formData);
    navigate("/seleccion-proyecto");
  };

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  return (
    <div className="min-h-screen bg-[#0A0A0A] py-8 px-4">
      <div className="max-w-3xl mx-auto">
        {/* Logo */}
        <div className="flex justify-center mb-8">
          <img src={logo} alt="Logo" className="h-16" />
        </div>

        {/* Card */}
        <div className="bg-[#1A1A1A] rounded-lg shadow-lg border border-[#2A2A2A] p-8">
          <h1 className="text-[#FAFAFA] mb-8 text-center">
            Registra Proyecto
          </h1>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label className="block mb-2 text-[#FAFAFA]">
                Nombre del Proyecto
              </label>
              <input
                type="text"
                name="projectName"
                value={formData.projectName}
                onChange={handleChange}
                className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                placeholder="Nombre de la serie, película u otro proyecto audiovisual"
              />
            </div>

            <div>
              <label className="block mb-2 text-[#FAFAFA]">Formato</label>
              <select
                name="format"
                value={formData.format}
                onChange={handleChange}
                className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
              >
                <option value="">Selecciona un formato</option>
                {formatOptions.map((format) => (
                  <option key={format} value={format}>
                    {format.charAt(0).toUpperCase() + format.slice(1)}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block mb-2 text-[#FAFAFA]">Género</label>
              <select
                name="genre"
                value={formData.genre}
                onChange={handleChange}
                className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
              >
                <option value="">Selecciona un género</option>
                {genreOptions.map((genre) => (
                  <option key={genre} value={genre}>
                    {genre.charAt(0).toUpperCase() + genre.slice(1)}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block mb-2 text-[#FAFAFA]">Sinopsis</label>
              <textarea
                name="synopsis"
                value={formData.synopsis}
                onChange={handleChange}
                rows={4}
                className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA] resize-none"
                placeholder="Detalle de lo que trata el producto audiovisual"
              />
            </div>

            <div>
              <label className="block mb-2 text-[#FAFAFA]">Director</label>
              <input
                type="text"
                name="director"
                value={formData.director}
                onChange={handleChange}
                className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                placeholder="Director o directores del producto audiovisual"
              />
            </div>

            <div className="flex justify-end pt-4">
              <button
                type="submit"
                className="bg-[#0B4F8A] text-white px-8 py-3 rounded-lg hover:bg-[#094170] transition-colors"
              >
                Finalizar
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
