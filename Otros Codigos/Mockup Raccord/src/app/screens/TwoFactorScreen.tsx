import { useState } from "react";
import { useNavigate } from "react-router";
import logo from "../../imports/Isotipo_Color.png";

export default function TwoFactorScreen() {
  const [code, setCode] = useState("");
  const navigate = useNavigate();

  const handleVerify = (e: React.FormEvent) => {
    e.preventDefault();
    navigate("/seleccion-proyecto");
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#0A0A0A] px-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="flex justify-center mb-8">
          <img src={logo} alt="Logo" className="w-24 h-24" />
        </div>

        {/* Card */}
        <div className="bg-[#1A1A1A] rounded-lg shadow-lg border border-[#2A2A2A] p-8">
          <h2 className="text-[#FAFAFA] mb-4 text-center">
            Verificación de Doble Factor
          </h2>

          <p className="text-[#6B6B6B] text-center mb-8">
            Hemos enviado un código de verificación a tu correo electrónico
          </p>

          <form onSubmit={handleVerify} className="space-y-6">
            <div>
              <label className="block mb-2 text-[#FAFAFA]">
                Código de Verificación
              </label>
              <input
                type="text"
                value={code}
                onChange={(e) => setCode(e.target.value)}
                className="w-full px-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA] text-center text-2xl tracking-widest"
                placeholder="000000"
                maxLength={6}
              />
            </div>

            <button
              type="submit"
              className="w-full bg-[#0B4F8A] text-white py-3 rounded-lg hover:bg-[#094170] transition-colors"
            >
              Verificar
            </button>
          </form>

          <div className="mt-6 text-center">
            <button className="text-[#0B4F8A] hover:underline">
              Reenviar código
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
