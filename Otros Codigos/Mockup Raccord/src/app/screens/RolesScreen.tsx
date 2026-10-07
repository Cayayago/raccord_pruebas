import { useState } from "react";
import { useLocation, useNavigate } from "react-router";
import {
  ArrowLeft, Users, Mail, Plus, Check, X, Pencil, Send,
  Clock, UserCheck, ChevronDown
} from "lucide-react";
import logo from "../../imports/Logo_Negativo.png";

const DEPARTMENTS = [
  "Dirección",
  "Producción",
  "Cámara y Fotografía",
  "Arte y Dirección de Arte",
  "Sonido",
  "Vestuario",
  "Maquillaje y Pelo",
  "Maquillaje FX",
  "Efectos Especiales (SFX)",
  "Efectos Visuales (VFX)",
  "Continuidad",
  "Casting",
  "Stunts",
  "Post-producción",
  "Locaciones",
  "Administración",
  "Otro",
];

const ROLES_BY_DEPT: Record<string, string[]> = {
  "Dirección": ["Director/a", "Director/a Asistente", "2do Asistente de Dirección", "Script Supervisor"],
  "Producción": ["Productor/a Ejecutivo/a", "Productor/a", "Productor/a de Línea", "Coordinador/a de Producción", "Asistente de Producción"],
  "Cámara y Fotografía": ["Director/a de Fotografía", "Operador/a de Cámara", "1er AC", "2do AC", "Gaffer", "Grip", "Eléctrico"],
  "Arte y Dirección de Arte": ["Director/a de Arte", "Asistente de Arte", "Escenógrafo/a", "Utilero/a", "Decorator/a"],
  "Sonido": ["Jefe de Sonido", "Boom Operator", "Técnico de Sonido"],
  "Vestuario": ["Diseñador/a de Vestuario", "Asistente de Vestuario", "Sastre/Costurera"],
  "Maquillaje y Pelo": ["Jefe de Maquillaje", "Maquillador/a", "Peluquero/a Estilista"],
  "Maquillaje FX": ["Maquillador/a FX", "Asistente FX"],
  "Efectos Especiales (SFX)": ["Coordinador/a SFX", "Técnico SFX", "Pirotécnico/a"],
  "Efectos Visuales (VFX)": ["Supervisor/a VFX", "Artista VFX", "Compositor/a"],
  "Continuidad": ["Supervisor/a de Continuidad", "Asistente de Continuidad"],
  "Casting": ["Director/a de Casting", "Asistente de Casting"],
  "Stunts": ["Coordinador/a de Stunts", "Doble de Acción", "Especialista"],
  "Post-producción": ["Editor/a", "Asistente de Edición", "Colorista", "Diseñador/a de Sonido"],
  "Locaciones": ["Manager de Locaciones", "Asistente de Locaciones"],
  "Administración": ["Contador/a", "Asistente Administrativo/a", "Abogado/a"],
  "Otro": ["Otro"],
};

interface TeamMember {
  id: string;
  fullName: string;
  email: string;
  area: string;
  role: string;
  status: "active" | "pending";
}

const initialMembers: TeamMember[] = [
  { id: "1", fullName: "Luisa Peralta Gómez",    email: "l.peralta@produccion.co",   area: "Dirección",                    role: "Director/a",                      status: "active" },
  { id: "2", fullName: "Felipe Cárdenas Ruiz",   email: "f.cardenas@produccion.co",  area: "Producción",                   role: "Productor/a de Línea",            status: "active" },
  { id: "3", fullName: "Valentina Ospina Cruz",  email: "v.ospina@produccion.co",    area: "Cámara y Fotografía",          role: "Director/a de Fotografía",        status: "active" },
  { id: "4", fullName: "Andrés Montoya Silva",   email: "a.montoya@produccion.co",   area: "Arte y Dirección de Arte",     role: "Director/a de Arte",              status: "active" },
  { id: "5", fullName: "Camila Ríos Herrera",    email: "c.rios@produccion.co",      area: "Continuidad",                  role: "Supervisor/a de Continuidad",     status: "active" },
  { id: "6", fullName: "Sebastián Vargas León",  email: "s.vargas@produccion.co",    area: "Sonido",                       role: "Jefe de Sonido",                  status: "active" },
  { id: "7", fullName: "Natalia Bermúdez Pardo", email: "n.bermudez@produccion.co",  area: "Vestuario",                    role: "Diseñador/a de Vestuario",        status: "active" },
  { id: "8", fullName: "Tomás Guerrero Arce",    email: "t.guerrero@gmail.com",      area: "Efectos Especiales (SFX)",     role: "Coordinador/a SFX",               status: "active" },
  { id: "9", fullName: "Isabel Salcedo Mora",    email: "i.salcedo@produccion.co",   area: "Maquillaje y Pelo",            role: "Jefe de Maquillaje",              status: "active" },
  { id: "10", fullName: "Rodrigo Castilla Vega", email: "r.castilla@vfx.studio",     area: "Efectos Visuales (VFX)",       role: "Supervisor/a VFX",                status: "pending" },
  { id: "11", fullName: "Alejandra Peña Cano",   email: "a.pena@postpro.co",         area: "Post-producción",              role: "Editor/a",                        status: "pending" },
];

interface EditState {
  memberId: string;
  field: "area" | "role";
}

export default function RolesScreen() {
  const location = useLocation();
  const navigate = useNavigate();
  const projectName = location.state?.projectName || "Proyecto";

  const [members, setMembers] = useState<TeamMember[]>(initialMembers);
  const [editState, setEditState] = useState<EditState | null>(null);
  const [tempValue, setTempValue] = useState("");

  const [inviteForm, setInviteForm] = useState({ name: "", email: "", area: "", role: "" });
  const [inviteSent, setInviteSent] = useState(false);
  const [showInvitePanel, setShowInvitePanel] = useState(false);

  const startEdit = (memberId: string, field: "area" | "role", currentValue: string) => {
    setEditState({ memberId, field });
    setTempValue(currentValue);
  };

  const commitEdit = () => {
    if (!editState) return;
    setMembers((prev) =>
      prev.map((m) =>
        m.id === editState.memberId ? { ...m, [editState.field]: tempValue } : m
      )
    );
    setEditState(null);
  };

  const cancelEdit = () => {
    setEditState(null);
    setTempValue("");
  };

  const handleAreaChange = (memberId: string, newArea: string) => {
    const defaultRole = ROLES_BY_DEPT[newArea]?.[0] || "";
    setMembers((prev) =>
      prev.map((m) =>
        m.id === memberId ? { ...m, area: newArea, role: defaultRole } : m
      )
    );
    setEditState(null);
  };

  const handleSendInvite = (e: React.FormEvent) => {
    e.preventDefault();
    const name = inviteForm.name.trim() || "Invitado/a";
    const email = inviteForm.email.trim() || "sin-correo@proyecto.co";
    const newMember: TeamMember = {
      id: String(Date.now()),
      fullName: name,
      email,
      area: inviteForm.area || "Otro",
      role: inviteForm.role || "Otro",
      status: "pending",
    };
    setMembers((prev) => [...prev, newMember]);
    setInviteForm({ name: "", email: "", area: "", role: "" });
    setInviteSent(true);
    setTimeout(() => {
      setInviteSent(false);
      setShowInvitePanel(false);
    }, 2500);
  };

  const activeCount = members.filter((m) => m.status === "active").length;
  const pendingCount = members.filter((m) => m.status === "pending").length;

  const isEditing = (memberId: string, field: "area" | "role") =>
    editState?.memberId === memberId && editState?.field === field;

  return (
    <div className="min-h-screen bg-[#0A0A0A]">
      {/* Header */}
      <header className="bg-[#1A1A1A] border-b border-[#2A2A2A] px-8 py-4 sticky top-0 z-40">
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate(-1)}
              className="flex items-center gap-1.5 text-[#6B6B6B] hover:text-[#FAFAFA] transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              <span className="text-sm">Volver</span>
            </button>
            <div className="w-px h-5 bg-[#2A2A2A]" />
            <img src={logo} alt="Logo" className="h-9" />
          </div>

          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 text-sm text-[#6B6B6B]">
              <Users className="w-4 h-4 text-[#7B5FCF]" />
              <span className="text-[#FAFAFA] font-medium">{projectName}</span>
              <span className="text-[#4A4A4A]">·</span>
              <span>Roles del Equipo</span>
            </div>

            <button
              onClick={() => setShowInvitePanel((p) => !p)}
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-[#7B5FCF] hover:bg-[#6a4eb8] text-white text-sm font-medium transition-colors"
            >
              <Mail className="w-4 h-4" />
              Invitar persona
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-8 py-8">
        {/* Title + stats */}
        <div className="flex items-start justify-between mb-8 flex-wrap gap-4">
          <div>
            <h1 className="text-[#FAFAFA] text-2xl font-semibold tracking-wide mb-1">
              Roles del Equipo
            </h1>
            <p className="text-[#6B6B6B] text-sm">
              Gestiona los departamentos y roles de cada integrante del proyecto.
            </p>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 px-4 py-2 bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg">
              <UserCheck className="w-4 h-4 text-[#3d9970]" />
              <span className="text-[#FAFAFA] font-semibold text-sm">{activeCount}</span>
              <span className="text-[#6B6B6B] text-xs">activos</span>
            </div>
            {pendingCount > 0 && (
              <div className="flex items-center gap-2 px-4 py-2 bg-[#1A1A1A] border border-[#2A2A2A] rounded-lg">
                <Clock className="w-4 h-4 text-[#F2A341]" />
                <span className="text-[#FAFAFA] font-semibold text-sm">{pendingCount}</span>
                <span className="text-[#6B6B6B] text-xs">pendientes</span>
              </div>
            )}
          </div>
        </div>

        {/* Invite panel */}
        {showInvitePanel && (
          <div className="mb-8 bg-[#1A1A1A] rounded-xl border border-[#7B5FCF]/40 overflow-hidden">
            <div className="bg-gradient-to-r from-[#7B5FCF] to-[#0B4F8A] px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Send className="w-4 h-4 text-white/70" />
                <div>
                  <p className="text-white/60 text-xs font-semibold tracking-widest uppercase">Nueva invitación</p>
                  <h2 className="text-white font-semibold">Invitar al equipo</h2>
                </div>
              </div>
              <button
                onClick={() => { setShowInvitePanel(false); setInviteSent(false); }}
                className="w-7 h-7 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors"
              >
                <X className="w-3.5 h-3.5 text-white" />
              </button>
            </div>

            {inviteSent ? (
              <div className="px-6 py-8 flex flex-col items-center gap-3">
                <div className="w-12 h-12 rounded-full bg-[#3d9970]/15 border border-[#3d9970]/30 flex items-center justify-center">
                  <Check className="w-6 h-6 text-[#3d9970]" />
                </div>
                <p className="text-[#FAFAFA] font-medium">¡Invitación enviada!</p>
                <p className="text-[#6B6B6B] text-sm">El integrante aparecerá como pendiente hasta que acepte.</p>
              </div>
            ) : (
              <form onSubmit={handleSendInvite} className="p-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                  <div>
                    <label className="block text-[#FAFAFA] text-sm font-medium mb-1.5">Nombre completo</label>
                    <input
                      type="text"
                      value={inviteForm.name}
                      onChange={(e) => setInviteForm({ ...inviteForm, name: e.target.value })}
                      placeholder="Nombre y apellidos"
                      className="w-full px-4 py-2.5 bg-[#0A0A0A] border border-[#2A2A2A] rounded-lg text-[#FAFAFA] placeholder:text-[#4A4A4A] text-sm focus:outline-none focus:ring-2 focus:ring-[#7B5FCF]"
                    />
                  </div>
                  <div>
                    <label className="block text-[#FAFAFA] text-sm font-medium mb-1.5">Correo electrónico</label>
                    <input
                      type="text"
                      value={inviteForm.email}
                      onChange={(e) => setInviteForm({ ...inviteForm, email: e.target.value })}
                      placeholder="correo@dominio.com"
                      className="w-full px-4 py-2.5 bg-[#0A0A0A] border border-[#2A2A2A] rounded-lg text-[#FAFAFA] placeholder:text-[#4A4A4A] text-sm focus:outline-none focus:ring-2 focus:ring-[#7B5FCF]"
                    />
                  </div>
                  <div>
                    <label className="block text-[#FAFAFA] text-sm font-medium mb-1.5">Área / Departamento</label>
                    <div className="relative">
                      <select
                        value={inviteForm.area}
                        onChange={(e) => setInviteForm({ ...inviteForm, area: e.target.value, role: ROLES_BY_DEPT[e.target.value]?.[0] || "" })}
                        className="w-full px-4 py-2.5 bg-[#0A0A0A] border border-[#2A2A2A] rounded-lg text-[#FAFAFA] text-sm focus:outline-none focus:ring-2 focus:ring-[#7B5FCF] appearance-none"
                      >
                        <option value="">Selecciona área</option>
                        {DEPARTMENTS.map((d) => (
                          <option key={d} value={d}>{d}</option>
                        ))}
                      </select>
                      <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#6B6B6B] pointer-events-none" />
                    </div>
                  </div>
                  <div>
                    <label className="block text-[#FAFAFA] text-sm font-medium mb-1.5">Rol</label>
                    <div className="relative">
                      <select
                        value={inviteForm.role}
                        onChange={(e) => setInviteForm({ ...inviteForm, role: e.target.value })}
                        className="w-full px-4 py-2.5 bg-[#0A0A0A] border border-[#2A2A2A] rounded-lg text-[#FAFAFA] text-sm focus:outline-none focus:ring-2 focus:ring-[#7B5FCF] appearance-none"
                      >
                        <option value="">Selecciona rol</option>
                        {(ROLES_BY_DEPT[inviteForm.area] || ROLES_BY_DEPT["Otro"]).map((r) => (
                          <option key={r} value={r}>{r}</option>
                        ))}
                      </select>
                      <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#6B6B6B] pointer-events-none" />
                    </div>
                  </div>
                </div>
                <div className="flex items-center justify-end gap-3">
                  <button
                    type="button"
                    onClick={() => setShowInvitePanel(false)}
                    className="px-5 py-2 rounded-lg border border-[#2A2A2A] text-[#6B6B6B] hover:text-[#FAFAFA] text-sm transition-all"
                  >
                    Cancelar
                  </button>
                  <button
                    type="submit"
                    className="flex items-center gap-2 px-6 py-2 rounded-lg bg-[#7B5FCF] hover:bg-[#6a4eb8] text-white text-sm font-semibold transition-all"
                  >
                    <Send className="w-3.5 h-3.5" />
                    Enviar invitación
                  </button>
                </div>
              </form>
            )}
          </div>
        )}

        {/* Team table */}
        <div className="bg-[#1A1A1A] rounded-xl border border-[#2A2A2A] overflow-hidden">
          {/* Table header */}
          <div className="grid grid-cols-[auto_1fr_1fr_1fr_auto] gap-0 px-5 py-3 border-b border-[#2A2A2A] bg-[#141414]">
            <div className="w-10" />
            <div className="text-[#6B6B6B] text-xs font-semibold tracking-widest uppercase">Nombre completo</div>
            <div className="text-[#6B6B6B] text-xs font-semibold tracking-widest uppercase">Área / Departamento</div>
            <div className="text-[#6B6B6B] text-xs font-semibold tracking-widest uppercase">Rol</div>
            <div className="text-[#6B6B6B] text-xs font-semibold tracking-widest uppercase w-24 text-center">Estado</div>
          </div>

          {/* Rows */}
          <div className="divide-y divide-[#1E1E1E]">
            {members.map((member) => (
              <div
                key={member.id}
                className="grid grid-cols-[auto_1fr_1fr_1fr_auto] gap-0 px-5 py-3.5 items-center hover:bg-[#1E1E1E] transition-colors"
              >
                {/* Avatar */}
                <div className="w-10 pr-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 ${
                    member.status === "pending" ? "bg-[#F2A341]/20 text-[#F2A341]" : "bg-[#7B5FCF]/20 text-[#7B5FCF]"
                  }`}>
                    {member.fullName.split(" ").slice(0, 2).map((n) => n[0]).join("").toUpperCase()}
                  </div>
                </div>

                {/* Name + email */}
                <div className="min-w-0 pr-4">
                  <p className="text-[#FAFAFA] text-sm font-medium truncate">{member.fullName}</p>
                  <p className="text-[#4A4A4A] text-xs truncate mt-0.5">{member.email}</p>
                </div>

                {/* Area – editable */}
                <div className="pr-4 min-w-0">
                  {isEditing(member.id, "area") ? (
                    <div className="flex items-center gap-1">
                      <div className="relative flex-1">
                        <select
                          autoFocus
                          value={tempValue}
                          onChange={(e) => setTempValue(e.target.value)}
                          className="w-full px-2 py-1.5 bg-[#0A0A0A] border border-[#7B5FCF] rounded text-[#FAFAFA] text-xs focus:outline-none appearance-none"
                        >
                          {DEPARTMENTS.map((d) => (
                            <option key={d} value={d}>{d}</option>
                          ))}
                        </select>
                      </div>
                      <button
                        onClick={() => handleAreaChange(member.id, tempValue)}
                        className="w-6 h-6 rounded bg-[#3d9970]/20 hover:bg-[#3d9970]/40 flex items-center justify-center flex-shrink-0 transition-colors"
                      >
                        <Check className="w-3 h-3 text-[#3d9970]" />
                      </button>
                      <button
                        onClick={cancelEdit}
                        className="w-6 h-6 rounded bg-[#C64545]/20 hover:bg-[#C64545]/40 flex items-center justify-center flex-shrink-0 transition-colors"
                      >
                        <X className="w-3 h-3 text-[#C64545]" />
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={() => startEdit(member.id, "area", member.area)}
                      className="group flex items-center gap-1.5 w-full text-left"
                    >
                      <span className="text-[#FAFAFA] text-sm truncate">{member.area}</span>
                      <Pencil className="w-3 h-3 text-[#4A4A4A] opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0" />
                    </button>
                  )}
                </div>

                {/* Role – editable */}
                <div className="pr-4 min-w-0">
                  {isEditing(member.id, "role") ? (
                    <div className="flex items-center gap-1">
                      <div className="relative flex-1">
                        <select
                          autoFocus
                          value={tempValue}
                          onChange={(e) => setTempValue(e.target.value)}
                          className="w-full px-2 py-1.5 bg-[#0A0A0A] border border-[#7B5FCF] rounded text-[#FAFAFA] text-xs focus:outline-none appearance-none"
                        >
                          {(ROLES_BY_DEPT[member.area] || ROLES_BY_DEPT["Otro"]).map((r) => (
                            <option key={r} value={r}>{r}</option>
                          ))}
                        </select>
                      </div>
                      <button
                        onClick={commitEdit}
                        className="w-6 h-6 rounded bg-[#3d9970]/20 hover:bg-[#3d9970]/40 flex items-center justify-center flex-shrink-0 transition-colors"
                      >
                        <Check className="w-3 h-3 text-[#3d9970]" />
                      </button>
                      <button
                        onClick={cancelEdit}
                        className="w-6 h-6 rounded bg-[#C64545]/20 hover:bg-[#C64545]/40 flex items-center justify-center flex-shrink-0 transition-colors"
                      >
                        <X className="w-3 h-3 text-[#C64545]" />
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={() => startEdit(member.id, "role", member.role)}
                      className="group flex items-center gap-1.5 w-full text-left"
                    >
                      <span className="text-[#6B6B6B] text-sm truncate">{member.role}</span>
                      <Pencil className="w-3 h-3 text-[#4A4A4A] opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0" />
                    </button>
                  )}
                </div>

                {/* Status badge */}
                <div className="w-24 flex justify-center">
                  {member.status === "active" ? (
                    <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#3d9970]/15 border border-[#3d9970]/25">
                      <span className="w-1.5 h-1.5 rounded-full bg-[#3d9970]" />
                      <span className="text-[#3d9970] text-xs font-medium">Activo</span>
                    </span>
                  ) : (
                    <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#F2A341]/10 border border-[#F2A341]/25">
                      <Clock className="w-3 h-3 text-[#F2A341]" />
                      <span className="text-[#F2A341] text-xs font-medium">Pendiente</span>
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>

          {/* Footer */}
          <div className="px-5 py-3 border-t border-[#2A2A2A] bg-[#141414] flex items-center justify-between">
            <p className="text-[#4A4A4A] text-xs">
              Haz clic en el nombre del área o rol para editarlo directamente.
            </p>
            <button
              onClick={() => setShowInvitePanel(true)}
              className="flex items-center gap-1.5 text-[#7B5FCF] hover:text-[#9b7fdf] text-xs transition-colors"
            >
              <Plus className="w-3.5 h-3.5" />
              Agregar integrante
            </button>
          </div>
        </div>
      </main>
    </div>
  );
}
