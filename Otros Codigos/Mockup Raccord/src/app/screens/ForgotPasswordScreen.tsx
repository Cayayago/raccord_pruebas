import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, Mail, CheckCircle, Shield } from "lucide-react";
import logo from "../../imports/Isotipo_Color.png";

export default function ForgotPasswordScreen() {
  const [email, setEmail] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      setSubmitted(true);
    }, 1200);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#0A0A0A] px-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="flex justify-center mb-8">
          <img src={logo} alt="Logo" className="w-20 h-20 opacity-90" />
        </div>

        {!submitted ? (
          <div className="bg-[#1A1A1A] rounded-xl shadow-2xl border border-[#2A2A2A] overflow-hidden">
            {/* Header Strip */}
            <div className="bg-gradient-to-r from-[#0B4F8A] to-[#7B5FCF] px-8 py-6">
              <div className="flex items-center gap-3 mb-1">
                <Shield className="w-5 h-5 text-white/80" />
                <span className="text-white/60 text-xs font-semibold tracking-widest uppercase">
                  Seguridad de cuenta
                </span>
              </div>
              <h1 className="text-white text-xl font-semibold tracking-wide">
                Recuperación de Acceso
              </h1>
              <p className="text-white/70 text-sm mt-1 leading-relaxed">
                Ingresa tu correo electrónico registrado y te enviaremos las instrucciones para restablecer tu contraseña o usuario.
              </p>
            </div>

            {/* Form */}
            <div className="p-8">
              <form onSubmit={handleSubmit} className="space-y-6">
                <div>
                  <label className="block mb-2 text-[#FAFAFA] text-sm font-medium tracking-wide">
                    Correo Electrónico
                  </label>
                  <div className="relative">
                    <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#6B6B6B]" />
                    <input
                      type="text"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="w-full pl-11 pr-4 py-3 border border-[#2A2A2A] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0B4F8A] bg-[#0A0A0A] text-[#FAFAFA] placeholder:text-[#4A4A4A] transition-all"
                      placeholder="correo@dominio.com"
                    />
                  </div>
                  <p className="mt-2 text-[#6B6B6B] text-xs leading-relaxed">
                    Debe coincidir con el correo asociado a tu cuenta en el sistema.
                  </p>
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full py-3 rounded-lg font-semibold tracking-wide transition-all flex items-center justify-center gap-2 bg-[#0B4F8A] text-white hover:bg-[#094170] shadow-lg shadow-[#0B4F8A]/20 disabled:opacity-60 disabled:cursor-not-allowed"
                >
                  {isLoading ? (
                    <>
                      <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      Enviando...
                    </>
                  ) : (
                    "Enviar Instrucciones"
                  )}
                </button>
              </form>

              {/* Divider */}
              <div className="mt-8 pt-6 border-t border-[#2A2A2A]">
                <button
                  onClick={() => navigate("/")}
                  className="flex items-center gap-2 text-[#6B6B6B] hover:text-[#FAFAFA] text-sm transition-colors mx-auto"
                >
                  <ArrowLeft className="w-4 h-4" />
                  Volver al inicio de sesión
                </button>
              </div>
            </div>
          </div>
        ) : (
          /* Success State */
          <div className="bg-[#1A1A1A] rounded-xl shadow-2xl border border-[#2A2A2A] overflow-hidden">
            <div className="bg-gradient-to-r from-[#1a4a2e] to-[#0B4F8A] px-8 py-6">
              <div className="flex items-center gap-3 mb-1">
                <CheckCircle className="w-5 h-5 text-[#3d9970]" />
                <span className="text-white/60 text-xs font-semibold tracking-widest uppercase">
                  Solicitud procesada
                </span>
              </div>
              <h1 className="text-white text-xl font-semibold tracking-wide">
                Correo enviado exitosamente
              </h1>
            </div>

            <div className="p-8">
              <div className="flex justify-center mb-6">
                <div className="w-16 h-16 rounded-full bg-[#3d9970]/15 border border-[#3d9970]/30 flex items-center justify-center">
                  <CheckCircle className="w-8 h-8 text-[#3d9970]" />
                </div>
              </div>

              <div className="text-center space-y-3 mb-8">
                <p className="text-[#FAFAFA] font-medium">
                  Hemos enviado las instrucciones a:
                </p>
                <p className="text-[#0B4F8A] font-semibold text-lg bg-[#0B4F8A]/10 rounded-lg py-2 px-4 border border-[#0B4F8A]/20">
                  {email}
                </p>
                <p className="text-[#6B6B6B] text-sm leading-relaxed max-w-sm mx-auto">
                  Revisa tu bandeja de entrada, incluyendo la carpeta de spam. El correo contiene el enlace para restablecer tu contraseña o recuperar tu nombre de usuario.
                </p>
              </div>

              <div className="bg-[#0A0A0A] border border-[#2A2A2A] rounded-lg p-4 mb-6">
                <p className="text-[#6B6B6B] text-xs leading-relaxed text-center">
                  <span className="text-[#FAFAFA] font-medium">Nota: </span>
                  El enlace de recuperación tiene una validez de <span className="text-[#E67E5C]">24 horas</span>. Si no recibes el correo en los próximos minutos, verifica que el correo ingresado sea el correcto.
                </p>
              </div>

              <div className="space-y-3">
                <button
                  onClick={() => { setSubmitted(false); setEmail(""); }}
                  className="w-full py-3 rounded-lg border border-[#2A2A2A] text-[#6B6B6B] hover:text-[#FAFAFA] hover:border-[#0B4F8A] text-sm font-medium tracking-wide transition-all"
                >
                  Intentar con otro correo
                </button>
                <button
                  onClick={() => navigate("/")}
                  className="w-full py-3 rounded-lg bg-[#0B4F8A] text-white hover:bg-[#094170] font-semibold tracking-wide transition-all shadow-lg shadow-[#0B4F8A]/20"
                >
                  Volver al Inicio de Sesión
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
