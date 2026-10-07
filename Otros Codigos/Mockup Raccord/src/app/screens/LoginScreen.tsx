import { useState } from "react";
import { useNavigate } from "react-router";
import { KeyRound } from "lucide-react";
import logo from "../../imports/Isotipo_Color.png";

export default function LoginScreen() {
  const [activeTab, setActiveTab] = useState<"ingresar" | "registrar">("ingresar");
  const navigate = useNavigate();

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    navigate("/verificacion");
  };

  const handleRegister = (e: React.FormEvent) => {
    e.preventDefault();
    navigate("/registro-proyecto");
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#0A0A0A] px-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="flex justify-center mb-8">
          <img src={logo} alt="Logo" className="w-24 h-24" />
        </div>

        {/* Card */}
        <div className="bg-[#1A1A1A] rounded-lg shadow-lg overflow-hidden border border-[#2A2A2A]">
          {/* Tabs */}
          <div className="flex border-b border-[#2A2A2A]">
            <button
              onClick={() => setActiveTab("ingresar")}
              className={`flex-1 py-4 px-6 transition-all ${
                activeTab === "ingresar"
                  ? "bg-[#0B4F8A] text-white"
                  : "bg-[#1A1A1A] text-[#6B6B6B] hover:bg-[#2A2A2A]"
              }`}
            >
              Ingresar
            </button>
            <button
              onClick={() => setActiveTab("registrar")}
              className={`flex-1 py-4 px-6 transition-all ${
                activeTab === "registrar"
                  ? "bg-[#0B4F8A] text-white"
                  : "bg-[#1A1A1A] text-[#6B6B6B] hover:bg-[#2A2A2A]"
              }`}
            >
              Registrar
            </button>
          </div>

          {/* Content */}
          <div className="p-8">
            {activeTab === "ingresar" ? (
              <form onSubmit={handleLogin} className="space-y-6">
                <div>
                  <label className="block mb-2 text-[#FAFAFA]">
                    Username o E-mail
                  </label>
                  <input
                    type="text"
                    className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                    placeholder="Ingresa tu usuario o correo"
                  />
                </div>

                <div>
                  <label className="block mb-2 text-[#FAFAFA]">
                    Contraseña
                  </label>
                  <input
                    type="password"
                    className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                    placeholder="Ingresa tu contraseña"
                  />
                </div>

                <button
                  type="submit"
                  className="w-full bg-[#0B4F8A] text-white py-3 rounded-lg hover:bg-[#094170] transition-colors"
                >
                  Ingresar
                </button>

                {/* Forgot credentials link */}
                <div className="pt-2 flex justify-center">
                  <button
                    type="button"
                    onClick={() => navigate("/recuperar-acceso")}
                    className="flex items-center gap-1.5 text-[#6B6B6B] hover:text-[#0B4F8A] text-sm transition-colors group"
                  >
                    <KeyRound className="w-3.5 h-3.5 group-hover:text-[#0B4F8A] transition-colors" />
                    <span>¿Olvidaste tu contraseña o usuario?</span>
                  </button>
                </div>
              </form>
            ) : (
              <form onSubmit={handleRegister} className="space-y-4">
                <div>
                  <label className="block mb-2 text-[#FAFAFA]">Nombres</label>
                  <input
                    type="text"
                    className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                    placeholder="Ingresa tus nombres"
                  />
                </div>

                <div>
                  <label className="block mb-2 text-[#FAFAFA]">Apellidos</label>
                  <input
                    type="text"
                    className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                    placeholder="Ingresa tus apellidos"
                  />
                </div>

                <div>
                  <label className="block mb-2 text-[#FAFAFA]">Celular</label>
                  <input
                    type="tel"
                    className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                    placeholder="Ingresa tu número de celular"
                  />
                </div>

                <div>
                  <label className="block mb-2 text-[#FAFAFA]">Email</label>
                  <input
                    type="email"
                    className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                    placeholder="Ingresa tu correo electrónico"
                  />
                </div>

                <div>
                  <label className="block mb-2 text-[#FAFAFA]">Contraseña</label>
                  <input
                    type="password"
                    className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                    placeholder="Crea una contraseña"
                  />
                </div>

                <div>
                  <label className="block mb-2 text-[#FAFAFA]">
                    Confirmar Contraseña
                  </label>
                  <input
                    type="password"
                    className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA]"
                    placeholder="Confirma tu contraseña"
                  />
                </div>

                <button
                  type="submit"
                  className="w-full bg-[#0B4F8A] text-white py-3 rounded-lg hover:bg-[#094170] transition-colors"
                >
                  Registrar
                </button>
              </form>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
