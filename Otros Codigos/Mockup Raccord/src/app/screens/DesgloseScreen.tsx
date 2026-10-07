import { useState, useRef, useEffect } from "react";
import { useLocation, useNavigate } from "react-router";
import {
  Menu, User, Globe, LogOut, ArrowLeft, FileDown, Filter,
  Sun, Moon, Sunrise, Sunset, ChevronDown, Plus, X, Check,
  Pencil, ChevronRight
} from "lucide-react";
import logo from "../../imports/Logo_Negativo.png";

type TimeOfDay = "Day" | "Night" | "Dawn" | "Evening";

const TIME_CONFIG: Record<TimeOfDay, { label: string; color: string; icon: React.FC<{ className?: string }> }> = {
  Day:     { label: "Día",       color: "#F2A341", icon: Sun },
  Night:   { label: "Noche",     color: "#4A7FA5", icon: Moon },
  Dawn:    { label: "Amanecer",  color: "#7B5FCF", icon: Sunrise },
  Evening: { label: "Atardecer", color: "#E67E5C", icon: Sunset },
};

const ALL_DEPTS = [
  { name: "Elenco",          color: "#0B4F8A" },
  { name: "Extras / BG",     color: "#6B6B6B" },
  { name: "Bits",            color: "#6B6B6B" },
  { name: "Props",           color: "#C09040" },
  { name: "Stunts",          color: "#C64545" },
  { name: "SFX",             color: "#E67E5C" },
  { name: "VFX",             color: "#7B5FCF" },
  { name: "Armas",           color: "#C64545" },
  { name: "Vehículos",       color: "#4A7FA5" },
  { name: "Animales",        color: "#3d9970" },
  { name: "Arte",            color: "#8B6B3D" },
  { name: "Maquillaje",      color: "#9B59B6" },
  { name: "Maquillaje FX",   color: "#C64545" },
  { name: "Vestuario",       color: "#6B7A8D" },
  { name: "Cámara",          color: "#0B4F8A" },
  { name: "Sonido",          color: "#2E86AB" },
  { name: "Crew Adicional",  color: "#6B6B6B" },
  { name: "Notas",           color: "#F2A341" },
];

const DEPT_COLOR: Record<string, string> = Object.fromEntries(ALL_DEPTS.map((d) => [d.name, d.color]));

interface DeptEntry {
  dept: string;
  items: string[];
}

interface SceneStrip {
  number: string;
  intExt: "INT" | "EXT" | "INT/EXT";
  locationDetail: string;
  timeOfDay: TimeOfDay;
  pages: string;
  departments: DeptEntry[];
}

interface LocationGroup {
  locationName: string;
  scenes: SceneStrip[];
}

interface ShootDay {
  dayNumber: number;
  date: string;
  city: string;
  callTime: string;
  totalPages: string;
  locationGroups: LocationGroup[];
}

interface Week {
  weekNumber: number;
  days: ShootDay[];
}

const menuOptions = [
  "Guión", "Crear Escenas", "Crear Personajes", "Crew List",
  "Plan de Rodaje", "Desglose", "Galería", "Roles",
];

const initialData: Week[] = [
  {
    weekNumber: 1,
    days: [
      {
        dayNumber: 1,
        date: "Lunes, 15 de Septiembre 2026",
        city: "Valle del Cauca",
        callTime: "5:30 AM",
        totalPages: "4 6/8",
        locationGroups: [
          {
            locationName: "Finca El Paraíso – Cabaña Interior",
            scenes: [
              {
                number: "1",
                intExt: "INT",
                locationDetail: "CABAÑA-SALA PRINCIPAL",
                timeOfDay: "Dawn",
                pages: "1 2/8",
                departments: [
                  { dept: "Elenco",    items: ["1. LUCÍA CAMACHO"] },
                  { dept: "Props",     items: ["Carta sellada con lacre rojo", "Vela casi consumida", "Baúl de madera colonial"] },
                  { dept: "SFX",       items: ["Niebla exterior filtrada por ventana"] },
                  { dept: "Arte",      items: ["Cabaña época años 50", "Cuadros religiosos", "Flores secas"] },
                  { dept: "Vestuario", items: ["Camisón de algodón blanco", "Chal de lana"] },
                  { dept: "Cámara",    items: ["Plano secuencia 2 min sin cortes", "Lente 35mm Zeiss"] },
                ],
              },
              {
                number: "2",
                intExt: "INT/EXT",
                locationDetail: "CABAÑA-PORCHE TRASERO",
                timeOfDay: "Dawn",
                pages: "4/8",
                departments: [
                  { dept: "Elenco",       items: ["1. LUCÍA CAMACHO", "3. DOÑA CARMEN"] },
                  { dept: "Extras / BG",  items: ["Peones de finca (8)"] },
                  { dept: "Props",        items: ["Taza de tinto humeante", "Mecedora de madera"] },
                  { dept: "Sonido",       items: ["Gallos", "Ambiente rural temprano"] },
                  { dept: "Arte",         items: ["Porche con enredaderas", "Orquídeas naturales"] },
                ],
              },
            ],
          },
          {
            locationName: "Finca El Paraíso – Jardín y Fuente",
            scenes: [
              {
                number: "4",
                intExt: "EXT",
                locationDetail: "JARDÍN-FUENTE COLONIAL",
                timeOfDay: "Night",
                pages: "1 6/8",
                departments: [
                  { dept: "Elenco",       items: ["1. LUCÍA CAMACHO", "2. SEBASTIÁN MORA"] },
                  { dept: "Extras / BG",  items: ["Invitados de fiesta (30)", "8 parejas bailando"] },
                  { dept: "Bits",         items: ["Mozo con bandeja", "Músico que observa"] },
                  { dept: "Props",        items: ["Copa de champaña (prop)", "Pañuelo bordado con iniciales", "Faroles de papel encendidos"] },
                  { dept: "SFX",          items: ["Música diegética de cuerda en set"] },
                  { dept: "Arte",         items: ["Jardín colonial iluminado con velas", "Fuente de piedra con agua real"] },
                  { dept: "Vestuario",    items: ["Lucía: vestido verde esmeralda años 50", "Sebastián: traje oscuro de lino"] },
                  { dept: "Maquillaje",   items: ["Lucía: labios rojos, cabello recogido", "Sebastián: gomina, afeitado perfecto"] },
                  { dept: "Cámara",       items: ["Dolly circular alrededor de la fuente", "Luces cálidas ámbar LED"] },
                ],
              },
              {
                number: "9",
                intExt: "EXT",
                locationDetail: "JARDÍN-CORREDOR DE ÁRBOLES",
                timeOfDay: "Night",
                pages: "4/8",
                departments: [
                  { dept: "Elenco",   items: ["2. SEBASTIÁN MORA", "4. ANDRÉS VALLEJO"] },
                  { dept: "Stunts",   items: ["Forcejeo contenido entre árboles", "Sin doble"] },
                  { dept: "Cámara",   items: ["Cámara en mano tensa", "Lente 50mm"] },
                  { dept: "Sonido",   items: ["Hojas", "Viento", "Respiración"] },
                ],
              },
            ],
          },
        ],
      },
      {
        dayNumber: 2,
        date: "Martes, 16 de Septiembre 2026",
        city: "Valle del Cauca",
        callTime: "4:45 AM",
        totalPages: "5 2/8",
        locationGroups: [
          {
            locationName: "Sendero de la Montaña",
            scenes: [
              {
                number: "3",
                intExt: "EXT",
                locationDetail: "SENDERO-CRUCE DEL RÍO",
                timeOfDay: "Dawn",
                pages: "2 4/8",
                departments: [
                  { dept: "Elenco",       items: ["1. LUCÍA CAMACHO", "5. PETRA SUÁREZ"] },
                  { dept: "Extras / BG",  items: ["Arrieros a caballo en fondo (4)"] },
                  { dept: "Props",        items: ["Bulto de lona con objetos", "Mapa dibujado a mano", "Lámpara de petróleo"] },
                  { dept: "Stunts",       items: ["Cruce de río con corriente moderada", "Doble para Lucía en toma lejana"] },
                  { dept: "SFX",          items: ["Niebla baja (máquinas × 2)", "Salpicadura controlada"] },
                  { dept: "Vestuario",    items: ["Ropa de época sencilla", "3 mudas por artista (tomas mojadas)"] },
                  { dept: "Crew Adicional", items: ["Seguridad acuática certificada (2)", "Bote de rescate"] },
                ],
              },
              {
                number: "5",
                intExt: "EXT",
                locationDetail: "CIMA-MIRADOR NATURAL",
                timeOfDay: "Dawn",
                pages: "1",
                departments: [
                  { dept: "Elenco",  items: ["1. LUCÍA CAMACHO"] },
                  { dept: "SFX",     items: ["Viento alto real"] },
                  { dept: "VFX",     items: ["Extensión de amanecer en horizonte (comp post)"] },
                  { dept: "Cámara",  items: ["Drone circular amplio", "Trípode lente 85mm"] },
                  { dept: "Notas",   items: ["Ventana de luz: 25 min máximo", "Equipo mínimo en cima"] },
                ],
              },
            ],
          },
          {
            locationName: "Finca El Paraíso – Salón Principal",
            scenes: [
              {
                number: "6",
                intExt: "INT",
                locationDetail: "SALÓN-COMEDOR COLONIAL",
                timeOfDay: "Evening",
                pages: "1 6/8",
                departments: [
                  { dept: "Elenco",       items: ["1. LUCÍA CAMACHO", "2. SEBASTIÁN MORA", "3. DOÑA CARMEN", "4. ANDRÉS VALLEJO"] },
                  { dept: "Extras / BG",  items: ["Sirvientes de fondo (5)"] },
                  { dept: "Props",        items: ["Mesa colonial con vajilla de loza", "Telegrama doblado junto al plato", "Retrato familiar al fondo", "Candelabros de plata"] },
                  { dept: "SFX",          items: ["Lluvia exterior suave (rig en ventanas laterales)"] },
                  { dept: "Arte",         items: ["Salón época impecable", "Flores naturales en centro de mesa"] },
                  { dept: "Cámara",       items: ["4 cámaras en L", "Master + 3 individuales sin corte", "Luces cálidas velas prácticas"] },
                ],
              },
            ],
          },
        ],
      },
      {
        dayNumber: 3,
        date: "Miércoles, 17 de Septiembre 2026",
        city: "Pueblo de Silvia, Cauca",
        callTime: "7:00 AM",
        totalPages: "3 4/8",
        locationGroups: [
          {
            locationName: "Plaza Central de Silvia",
            scenes: [
              {
                number: "12",
                intExt: "EXT",
                locationDetail: "PLAZA-FRENTE A LA IGLESIA",
                timeOfDay: "Day",
                pages: "1 2/8",
                departments: [
                  { dept: "Elenco",       items: ["1. LUCÍA CAMACHO", "6. CORONEL RÍOS"] },
                  { dept: "Extras / BG",  items: ["Feligreses y marchantes (45)", "6 en primer plano con trajes guambianos"] },
                  { dept: "Props",        items: ["Carruaje de época (prop arte)", "Periódico local 1952", "Bastón del Coronel"] },
                  { dept: "SFX",          items: ["Campanadas de iglesia (playback sincronizado)"] },
                  { dept: "Vehículos",    items: ["Carruaje prop (tracción animal)"] },
                  { dept: "Animales",     items: ["1 caballo percherón entrenado para set"] },
                  { dept: "Vestuario",    items: ["Coronel: uniforme militar de época", "Lucía: vestido de viajera"] },
                ],
              },
              {
                number: "14",
                intExt: "EXT",
                locationDetail: "PLAZA-PUESTO DE MERCADO",
                timeOfDay: "Day",
                pages: "2 2/8",
                departments: [
                  { dept: "Elenco",       items: ["1. LUCÍA CAMACHO", "5. PETRA SUÁREZ", "7. NIÑA ISABEL"] },
                  { dept: "Extras / BG",  items: ["Vendedores y compradores (25)"] },
                  { dept: "Bits",         items: ["Vendedora de flores con frase", "Anciano que escucha"] },
                  { dept: "Props",        items: ["Flores frescas (varias canastas)", "Cesta de mimbre con doble fondo", "Monedas de época"] },
                  { dept: "Stunts",       items: ["Empujón en multitud", "Caída leve de Lucía al suelo"] },
                  { dept: "Crew Adicional", items: ["1 tutor para menor de edad en set"] },
                ],
              },
            ],
          },
        ],
      },
    ],
  },
  {
    weekNumber: 2,
    days: [
      {
        dayNumber: 8,
        date: "Lunes, 22 de Septiembre 2026",
        city: "Cali, Valle del Cauca",
        callTime: "6:00 AM",
        totalPages: "6",
        locationGroups: [
          {
            locationName: "Mercado Galería Alameda",
            scenes: [
              {
                number: "18",
                intExt: "INT/EXT",
                locationDetail: "MERCADO-PASILLO CENTRAL",
                timeOfDay: "Day",
                pages: "1 4/8",
                departments: [
                  { dept: "Elenco",       items: ["1. LUCÍA CAMACHO", "2. SEBASTIÁN MORA"] },
                  { dept: "Extras / BG",  items: ["Comerciantes y compradores (60)"] },
                  { dept: "Props",        items: ["Paquete envuelto en papel kraft", "Revólver de época (muda)", "Maletín de cuero"] },
                  { dept: "Armas",        items: ["Revólver prop mudo (registro en set, custodia armería)"] },
                  { dept: "Sonido",       items: ["Ambiente mercado caleño", "Pregones", "Cumbia lejana"] },
                  { dept: "Cámara",       items: ["Steady en pasillo", "2 cámaras de cobertura ocultas"] },
                ],
              },
              {
                number: "21",
                intExt: "EXT",
                locationDetail: "MERCADO-CALLEJÓN LATERAL",
                timeOfDay: "Day",
                pages: "2/8",
                departments: [
                  { dept: "Elenco",   items: ["4. ANDRÉS VALLEJO", "6. CORONEL RÍOS"] },
                  { dept: "Stunts",   items: ["Intercambio de documentos bajo presión", "Manotazo sobre pared"] },
                  { dept: "Cámara",   items: ["Cámara en mano", "Lente 28mm angulado"] },
                ],
              },
            ],
          },
          {
            locationName: "Plaza de Caicedo",
            scenes: [
              {
                number: "24",
                intExt: "EXT",
                locationDetail: "PLAZA-BANCA FRENTE AL BUSTO",
                timeOfDay: "Evening",
                pages: "2",
                departments: [
                  { dept: "Elenco",       items: ["1. LUCÍA CAMACHO", "6. CORONEL RÍOS"] },
                  { dept: "Extras / BG",  items: ["Paseantes vespertinos (20)"] },
                  { dept: "Props",        items: ["Maletín de cuero marrón", "Fotografías comprometedoras (prop)", "Cigarrillo de época"] },
                  { dept: "Cámara",       items: ["Dolly lento atrás en diálogo", "Luces cálidas golden hour"] },
                  { dept: "Notas",        items: ["Hora dorada: 5:40-6:10 PM", "Tener listo a las 5:20 PM"] },
                ],
              },
              {
                number: "26",
                intExt: "EXT",
                locationDetail: "PLAZA-ACCESO NORTE",
                timeOfDay: "Night",
                pages: "2 2/8",
                departments: [
                  { dept: "Elenco",        items: ["1. LUCÍA CAMACHO", "2. SEBASTIÁN MORA", "4. ANDRÉS VALLEJO"] },
                  { dept: "Stunts",        items: ["Persecución a pie hasta esquina", "Caída controlada Andrés", "Forcejeo doble"] },
                  { dept: "SFX",           items: ["Lluvia artificial (rig 20m)", "Humo ambiental"] },
                  { dept: "VFX",           items: ["Relámpago en fondo de fachada (comp post)"] },
                  { dept: "Maquillaje FX", items: ["Sebastián: herida ceja", "Lucía: rasguño en mano"] },
                  { dept: "Crew Adicional", items: ["Médico en set", "PA × 4 en esquinas"] },
                ],
              },
            ],
          },
        ],
      },
      {
        dayNumber: 9,
        date: "Martes, 23 de Septiembre 2026",
        city: "Cali, Valle del Cauca",
        callTime: "7:30 AM",
        totalPages: "4 6/8",
        locationGroups: [
          {
            locationName: "Hotel Aristi – Habitación 205",
            scenes: [
              {
                number: "28",
                intExt: "INT",
                locationDetail: "HOTEL-HABITACIÓN 205",
                timeOfDay: "Day",
                pages: "1 6/8",
                departments: [
                  { dept: "Elenco",   items: ["1. LUCÍA CAMACHO", "5. PETRA SUÁREZ"] },
                  { dept: "Props",    items: ["Máquina de escribir Olivetti Lettera 22", "Cartas apiladas", "Maleta abierta", "Mapa marcado con rutas"] },
                  { dept: "SFX",      items: ["Ventilador de techo girando (práctica)"] },
                  { dept: "Arte",     items: ["Habitación hotel años 50", "Documentos esparcidos", "Luz de persiana"] },
                  { dept: "Vestuario", items: ["Lucía: bata de hotel", "Petra: ropa de calle"] },
                ],
              },
            ],
          },
          {
            locationName: "Iglesia La Merced – Nave Central",
            scenes: [
              {
                number: "31",
                intExt: "INT",
                locationDetail: "IGLESIA-NAVE CENTRAL",
                timeOfDay: "Day",
                pages: "3",
                departments: [
                  { dept: "Elenco",       items: ["1. LUCÍA CAMACHO", "2. SEBASTIÁN MORA", "3. DOÑA CARMEN"] },
                  { dept: "Extras / BG",  items: ["Feligreses en bancas (35)", "5 en primeros planos"] },
                  { dept: "Bits",         items: ["Sacerdote que pasa", "Monaguillo con incensario"] },
                  { dept: "Props",        items: ["Velas encendidas (prop gas)", "Rosario antiguo de nácar", "Sobre con sello de cera rojo", "Biblia con páginas marcadas"] },
                  { dept: "SFX",          items: ["Eco natural de la iglesia", "Incienso real"] },
                  { dept: "Arte",         items: ["Velas prácticas añadidas", "Flores blancas en altares"] },
                  { dept: "Cámara",       items: ["Dolly en rieles 25m hacia el altar", "Luces naturales de ventanales"] },
                  { dept: "Sonido",       items: ["Eco de pasos en piedra", "Órgano diegético (organista en set)"] },
                ],
              },
            ],
          },
        ],
      },
    ],
  },
];

// ── helpers ──────────────────────────────────────────────────────────────────

function updateSceneInData(
  data: Week[],
  sceneNumber: string,
  updater: (s: SceneStrip) => SceneStrip
): Week[] {
  return data.map((w) => ({
    ...w,
    days: w.days.map((d) => ({
      ...d,
      locationGroups: d.locationGroups.map((g) => ({
        ...g,
        scenes: g.scenes.map((s) => (s.number === sceneNumber ? updater(s) : s)),
      })),
    })),
  }));
}

function generatePDFHTML(data: Week[], projectName: string): string {
  let rows = "";
  for (const week of data) {
    rows += `<tr class="week-row"><td colspan="6">SEMANA ${week.weekNumber}</td></tr>`;
    for (const day of week.days) {
      rows += `<tr class="day-row"><td colspan="6">DÍA ${day.dayNumber} · ${day.date} · ${day.city} · Llamado: ${day.callTime} · Total: ${day.totalPages} págs.</td></tr>`;
      for (const group of day.locationGroups) {
        rows += `<tr class="loc-row"><td colspan="6">${group.locationName}</td></tr>`;
        for (const sc of group.scenes) {
          const timeLabels: Record<TimeOfDay, string> = { Day: "Día", Night: "Noche", Dawn: "Amanecer", Evening: "Atardecer" };
          const deptSummary = sc.departments.map((d) => `<strong>${d.dept}:</strong> ${d.items.join(", ")}`).join("<br>");
          rows += `<tr>
            <td class="sc-num">${sc.number}</td>
            <td class="badge">${sc.intExt}</td>
            <td class="loc-detail">${sc.locationDetail}</td>
            <td class="time">${timeLabels[sc.timeOfDay]}</td>
            <td class="dept-col">${deptSummary}</td>
            <td class="pages">${sc.pages}</td>
          </tr>`;
        }
      }
      rows += `<tr class="end-day"><td colspan="5">Fin Día #${day.dayNumber}</td><td class="pages">Total: ${day.totalPages}</td></tr>`;
    }
  }
  return `<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8"><title>Desglose – ${projectName}</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family: Arial, sans-serif; font-size:9px; color:#111; background:#fff; }
  .page-header { border-bottom:2px solid #111; padding-bottom:8px; margin-bottom:14px; display:flex; justify-content:space-between; align-items:flex-end; }
  .page-header h1 { font-size:16px; font-weight:700; }
  .page-header .meta { font-size:8px; color:#555; text-align:right; line-height:1.6; }
  table { width:100%; border-collapse:collapse; }
  thead th { background:#111; color:#fff; padding:4px 6px; text-align:left; font-size:8px; letter-spacing:.08em; text-transform:uppercase; }
  td { padding:3px 6px; border-bottom:1px solid #e5e5e5; vertical-align:top; }
  tr:nth-child(even) td { background:#f9f9f9; }
  .week-row td { background:#111!important; color:#fff; font-weight:700; font-size:10px; letter-spacing:.1em; padding:5px 6px; }
  .day-row td { background:#333!important; color:#fff; font-size:8.5px; padding:4px 6px; }
  .loc-row td { background:#666!important; color:#ddd; font-size:8px; font-style:italic; padding:3px 6px; }
  .end-day td { background:#eee!important; color:#555; font-style:italic; font-size:8px; }
  .sc-num { font-weight:700; font-size:11px; width:28px; }
  .badge { font-family:monospace; border:1px solid #ccc; border-radius:2px; padding:1px 4px; font-size:8px; width:52px; }
  .loc-detail { font-weight:600; }
  .dept-col { line-height:1.6; }
  .pages { text-align:right; font-weight:700; white-space:nowrap; }
  @media print { body { -webkit-print-color-adjust:exact; print-color-adjust:exact; } }
</style></head><body>
<div class="page-header">
  <div><div style="font-size:8px;text-transform:uppercase;letter-spacing:.12em;color:#555;margin-bottom:3px;">Desglose de Producción</div><h1>${projectName}</h1></div>
  <div class="meta">Semanas: ${data.length} · Días: ${data.reduce((a, w) => a + w.days.length, 0)}<br>
  Generado: ${new Date().toLocaleDateString("es-CO", { day: "2-digit", month: "long", year: "numeric" })}</div>
</div>
<table>
  <thead><tr><th>Sc.</th><th>Int/Ext</th><th>Locación</th><th>Momento</th><th>Departamentos y requerimientos</th><th>Págs.</th></tr></thead>
  <tbody>${rows}</tbody>
</table>
<div style="margin-top:14px;border-top:1px solid #ccc;padding-top:6px;display:flex;justify-content:space-between;font-size:7.5px;color:#888;">
  <span>Documento de uso interno. No distribuir.</span>
</div>
</body></html>`;
}

function downloadPDF(data: Week[], projectName: string) {
  const html = generatePDFHTML(data, projectName);
  const win = window.open("", "_blank", "width=900,height=700");
  if (!win) { alert("Permite ventanas emergentes para exportar el PDF."); return; }
  win.document.write(html);
  win.document.close();
  setTimeout(() => { win.focus(); win.print(); }, 600);
}

// ── Sub-component: editable tag list ─────────────────────────────────────────

function TagEditor({
  dept,
  items,
  color,
  onUpdate,
  onRemoveDept,
}: {
  dept: string;
  items: string[];
  color: string;
  onUpdate: (newItems: string[]) => void;
  onRemoveDept: () => void;
}) {
  const [editingIdx, setEditingIdx] = useState<number | null>(null);
  const [editVal, setEditVal] = useState("");
  const [adding, setAdding] = useState(false);
  const [newVal, setNewVal] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);
  const addRef = useRef<HTMLInputElement>(null);

  useEffect(() => { if (editingIdx !== null) inputRef.current?.focus(); }, [editingIdx]);
  useEffect(() => { if (adding) addRef.current?.focus(); }, [adding]);

  const commitEdit = (idx: number) => {
    const trimmed = editVal.trim();
    if (trimmed) {
      const next = [...items];
      next[idx] = trimmed;
      onUpdate(next);
    }
    setEditingIdx(null);
  };

  const removeItem = (idx: number) => {
    onUpdate(items.filter((_, i) => i !== idx));
  };

  const commitAdd = () => {
    const trimmed = newVal.trim();
    if (trimmed) onUpdate([...items, trimmed]);
    setNewVal("");
    setAdding(false);
  };

  return (
    <div className="py-2.5 border-b border-[#1A1A1A] last:border-0">
      <div className="flex items-center justify-between mb-2">
        <span
          className="text-[10px] font-bold tracking-widest uppercase px-2 py-0.5 rounded"
          style={{ color, backgroundColor: `${color}20` }}
        >
          {dept}
        </span>
        <button
          onClick={onRemoveDept}
          className="text-[#4A4A4A] hover:text-[#C64545] transition-colors"
          title="Eliminar departamento"
        >
          <X className="w-3 h-3" />
        </button>
      </div>

      <div className="flex flex-wrap gap-1.5 items-center">
        {items.map((item, idx) => (
          editingIdx === idx ? (
            <div key={idx} className="flex items-center gap-1">
              <input
                ref={inputRef}
                value={editVal}
                onChange={(e) => setEditVal(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") commitEdit(idx);
                  if (e.key === "Escape") setEditingIdx(null);
                }}
                onBlur={() => commitEdit(idx)}
                className="px-2 py-0.5 bg-[#0A0A0A] border border-[#7B5FCF] rounded text-[#FAFAFA] text-xs focus:outline-none w-48"
              />
              <button onClick={() => commitEdit(idx)} className="text-[#3d9970]"><Check className="w-3 h-3" /></button>
            </div>
          ) : (
            <div
              key={idx}
              className="group flex items-center gap-1 bg-[#2A2A2A] hover:bg-[#303030] rounded px-2 py-0.5 cursor-pointer transition-colors"
              onClick={() => { setEditingIdx(idx); setEditVal(item); }}
            >
              <span className="text-[#FAFAFA] text-xs">{item}</span>
              <Pencil className="w-2.5 h-2.5 text-[#4A4A4A] opacity-0 group-hover:opacity-100 transition-opacity" />
              <button
                onClick={(e) => { e.stopPropagation(); removeItem(idx); }}
                className="text-[#4A4A4A] hover:text-[#C64545] opacity-0 group-hover:opacity-100 transition-all"
              >
                <X className="w-2.5 h-2.5" />
              </button>
            </div>
          )
        ))}

        {adding ? (
          <div className="flex items-center gap-1">
            <input
              ref={addRef}
              value={newVal}
              onChange={(e) => setNewVal(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") commitAdd();
                if (e.key === "Escape") { setAdding(false); setNewVal(""); }
              }}
              onBlur={commitAdd}
              placeholder="Agregar item..."
              className="px-2 py-0.5 bg-[#0A0A0A] border border-[#7B5FCF] rounded text-[#FAFAFA] text-xs focus:outline-none w-44 placeholder:text-[#4A4A4A]"
            />
          </div>
        ) : (
          <button
            onClick={() => setAdding(true)}
            className="flex items-center gap-1 text-[#4A4A4A] hover:text-[#7B5FCF] text-xs border border-dashed border-[#2A2A2A] hover:border-[#7B5FCF] rounded px-2 py-0.5 transition-all"
          >
            <Plus className="w-3 h-3" />
            Agregar
          </button>
        )}
      </div>
    </div>
  );
}

// ── Main component ────────────────────────────────────────────────────────────

export default function DesgloseScreen() {
  const location = useLocation();
  const navigate = useNavigate();
  const projectName = location.state?.projectName || "Proyecto";

  const [data, setData] = useState<Week[]>(initialData);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  const [selectedWeek, setSelectedWeek] = useState<number | "all">("all");
  const [selectedTime, setSelectedTime] = useState<TimeOfDay | "all">("all");
  const [expandedDays, setExpandedDays] = useState<Set<string>>(new Set(["1-1"]));
  const [expandedScenes, setExpandedScenes] = useState<Set<string>>(new Set());
  const [addDeptScene, setAddDeptScene] = useState<string | null>(null);
  const [newDeptName, setNewDeptName] = useState("");

  const handleMenuOption = (option: string) => {
    setIsMenuOpen(false);
    if (option === "Guión") navigate("/guiones", { state: { projectName } });
    else if (option === "Crear Escenas") navigate("/crear-escena", { state: { projectName } });
    else if (option === "Crear Personajes") navigate("/crear-personaje", { state: { projectName } });
    else if (option === "Crew List") navigate("/crew-list", { state: { projectName } });
    else if (option === "Galería") navigate("/galeria", { state: { projectName } });
    else if (option === "Plan de Rodaje") navigate("/plan-de-rodaje", { state: { projectName } });
    else if (option === "Desglose") navigate("/desglose", { state: { projectName } });
    else if (option === "Roles") navigate("/roles", { state: { projectName } });
  };

  const toggleDay = (key: string) => {
    setExpandedDays((prev) => { const n = new Set(prev); n.has(key) ? n.delete(key) : n.add(key); return n; });
  };

  const toggleScene = (key: string) => {
    setExpandedScenes((prev) => { const n = new Set(prev); n.has(key) ? n.delete(key) : n.add(key); return n; });
  };

  const updateDeptItems = (sceneNumber: string, deptName: string, newItems: string[]) => {
    setData((prev) =>
      updateSceneInData(prev, sceneNumber, (sc) => ({
        ...sc,
        departments: sc.departments.map((d) =>
          d.dept === deptName ? { ...d, items: newItems } : d
        ),
      }))
    );
  };

  const removeDept = (sceneNumber: string, deptName: string) => {
    setData((prev) =>
      updateSceneInData(prev, sceneNumber, (sc) => ({
        ...sc,
        departments: sc.departments.filter((d) => d.dept !== deptName),
      }))
    );
  };

  const addDept = (sceneNumber: string) => {
    const name = newDeptName.trim();
    if (!name) return;
    setData((prev) =>
      updateSceneInData(prev, sceneNumber, (sc) => {
        if (sc.departments.find((d) => d.dept === name)) return sc;
        return { ...sc, departments: [...sc.departments, { dept: name, items: [] }] };
      })
    );
    setNewDeptName("");
    setAddDeptScene(null);
  };

  const filtered = data
    .filter((w) => selectedWeek === "all" || w.weekNumber === selectedWeek)
    .map((w) => ({
      ...w,
      days: w.days.map((d) => ({
        ...d,
        locationGroups: d.locationGroups.map((g) => ({
          ...g,
          scenes: g.scenes.filter((s) => selectedTime === "all" || s.timeOfDay === selectedTime),
        })).filter((g) => g.scenes.length > 0),
      })).filter((d) => d.locationGroups.length > 0),
    })).filter((w) => w.days.length > 0);

  return (
    <div className="min-h-screen bg-[#0A0A0A]">
      {/* Header */}
      <header className="bg-[#1A1A1A] border-b border-[#2A2A2A] px-8 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button onClick={() => navigate(-1)} className="text-[#FAFAFA] hover:text-[#0B4F8A] transition-colors">
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

          <h2 className="text-[#FAFAFA]">{projectName} – Desglose</h2>

          <div className="flex items-center gap-3">
            <button
              onClick={() => downloadPDF(data, projectName)}
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-[#0B4F8A] hover:bg-[#094170] text-white text-sm font-medium transition-colors"
            >
              <FileDown className="w-4 h-4" />
              PDF
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
                  <button onClick={() => { navigate("/perfil", { state: { projectName } }); setIsProfileMenuOpen(false); }}
                    className="w-full px-4 py-2 text-left text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors flex items-center gap-3">
                    <User className="w-4 h-4" /> Perfil
                  </button>
                  <button onClick={() => setIsProfileMenuOpen(false)}
                    className="w-full px-4 py-2 text-left text-[#FAFAFA] hover:bg-[#2A2A2A] transition-colors flex items-center gap-3">
                    <Globe className="w-4 h-4" /> Cambio de Idioma
                  </button>
                  <button onClick={() => navigate("/")}
                    className="w-full px-4 py-2 text-left text-red-500 hover:bg-[#2A2A2A] transition-colors flex items-center gap-3">
                    <LogOut className="w-4 h-4" /> Salir
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
          <div className="max-w-7xl mx-auto flex gap-2 flex-wrap">
            {menuOptions.map((option) => (
              <button key={option} onClick={() => handleMenuOption(option)}
                className="px-4 py-2 text-[#FAFAFA] hover:bg-[#2A2A2A] rounded-lg transition-colors text-sm">
                {option}
              </button>
            ))}
          </div>
        </div>
      )}

      <main className="max-w-7xl mx-auto px-8 py-8">
        <div className="mb-6">
          <h1 className="text-[#FAFAFA] text-2xl font-semibold tracking-wide mb-1">Desglose de Producción</h1>
          <p className="text-[#6B6B6B] text-sm">
            Haz clic en una escena para ver y editar los requerimientos por departamento.
          </p>
        </div>

        {/* Filters */}
        <div className="flex flex-wrap items-center gap-3 mb-8 p-4 bg-[#1A1A1A] rounded-xl border border-[#2A2A2A]">
          <div className="flex items-center gap-2 text-[#6B6B6B] text-sm mr-2">
            <Filter className="w-4 h-4" />
            <span>Filtrar:</span>
          </div>
          <div className="flex items-center gap-1">
            {(["all", 1, 2] as const).map((w) => (
              <button key={w} onClick={() => setSelectedWeek(w)}
                className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${selectedWeek === w ? "bg-[#0B4F8A] text-white" : "bg-[#2A2A2A] text-[#6B6B6B] hover:text-[#FAFAFA]"}`}>
                {w === "all" ? "Todas las semanas" : `Semana ${w}`}
              </button>
            ))}
          </div>
          <div className="w-px h-5 bg-[#2A2A2A]" />
          <div className="flex items-center gap-1">
            <button onClick={() => setSelectedTime("all")}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${selectedTime === "all" ? "bg-[#2A2A2A] text-[#FAFAFA] ring-1 ring-[#4A4A4A]" : "text-[#6B6B6B] hover:text-[#FAFAFA]"}`}>
              Todos
            </button>
            {(Object.entries(TIME_CONFIG) as [TimeOfDay, typeof TIME_CONFIG[TimeOfDay]][]).map(([key, cfg]) => {
              const Icon = cfg.icon;
              return (
                <button key={key} onClick={() => setSelectedTime(key)}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${selectedTime === key ? "text-white" : "text-[#6B6B6B] hover:text-[#FAFAFA]"}`}
                  style={selectedTime === key ? { backgroundColor: cfg.color } : {}}>
                  <Icon className="w-3 h-3" />
                  {cfg.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Data */}
        <div className="space-y-8">
          {filtered.map((week) => (
            <div key={week.weekNumber}>
              <div className="flex items-center gap-3 mb-4">
                <div className="bg-[#0B4F8A] text-white text-xs font-bold px-3 py-1 rounded-full tracking-widest uppercase">
                  Semana {week.weekNumber}
                </div>
                <div className="flex-1 h-px bg-[#2A2A2A]" />
              </div>

              <div className="space-y-4">
                {week.days.map((day) => {
                  const dayKey = `${week.weekNumber}-${day.dayNumber}`;
                  const isExpanded = expandedDays.has(dayKey);
                  return (
                    <div key={day.dayNumber} className="bg-[#1A1A1A] rounded-xl border border-[#2A2A2A] overflow-hidden">
                      <button onClick={() => toggleDay(dayKey)}
                        className="w-full flex items-center justify-between px-5 py-4 hover:bg-[#202020] transition-colors">
                        <div className="flex items-center gap-4">
                          <span className="text-[#0B4F8A] font-bold text-lg">DÍA {day.dayNumber}</span>
                          <div className="w-px h-8 bg-[#2A2A2A]" />
                          <div className="text-left">
                            <p className="text-[#FAFAFA] font-medium text-sm">{day.date}</p>
                            <p className="text-[#6B6B6B] text-xs mt-0.5">{day.city} · Llamado: {day.callTime} · Total: {day.totalPages} págs.</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="text-[#6B6B6B] text-xs">
                            {day.locationGroups.reduce((a, g) => a + g.scenes.length, 0)} escenas
                          </span>
                          <ChevronDown className={`w-4 h-4 text-[#6B6B6B] transition-transform ${isExpanded ? "rotate-180" : ""}`} />
                        </div>
                      </button>

                      {isExpanded && (
                        <div className="border-t border-[#2A2A2A]">
                          {day.locationGroups.map((group, gi) => (
                            <div key={gi} className={gi > 0 ? "border-t border-[#1E1E1E]" : ""}>
                              <div className="px-5 py-2.5 bg-[#141414] flex items-center gap-2">
                                <span className="text-[#6B6B6B] text-xs font-semibold tracking-widest uppercase">{group.locationName}</span>
                              </div>

                              <div className="divide-y divide-[#1E1E1E]">
                                {group.scenes.map((scene) => {
                                  const timeCfg = TIME_CONFIG[scene.timeOfDay];
                                  const TimeIcon = timeCfg.icon;
                                  const sceneKey = `${week.weekNumber}-${day.dayNumber}-${scene.number}`;
                                  const isSceneExpanded = expandedScenes.has(sceneKey);
                                  const usedDeptNames = scene.departments.map((d) => d.dept);

                                  return (
                                    <div key={scene.number}>
                                      {/* Scene strip */}
                                      <button onClick={() => toggleScene(sceneKey)}
                                        className="w-full flex items-stretch hover:bg-[#1E1E1E] transition-colors text-left">
                                        <div className="w-1 flex-shrink-0" style={{ backgroundColor: timeCfg.color }} />
                                        <div className="flex-shrink-0 w-16 flex flex-col items-center justify-center px-3 py-3 border-r border-[#1E1E1E]">
                                          <span className="text-[#FAFAFA] font-bold text-base leading-none">{scene.number}</span>
                                          <span className="text-[#4A4A4A] text-[10px] mt-0.5">Sc.</span>
                                        </div>
                                        <div className="flex-1 px-4 py-3 min-w-0">
                                          <div className="flex items-center gap-2 flex-wrap">
                                            <span className="text-[#6B6B6B] text-xs font-mono border border-[#2A2A2A] rounded px-1.5 py-0.5">{scene.intExt}</span>
                                            <span className="text-[#FAFAFA] text-sm font-medium">{scene.locationDetail}</span>
                                            <div className="flex items-center gap-1 text-xs px-2 py-0.5 rounded-full"
                                              style={{ color: timeCfg.color, backgroundColor: `${timeCfg.color}20` }}>
                                              <TimeIcon className="w-3 h-3" />
                                              <span>{timeCfg.label}</span>
                                            </div>
                                          </div>
                                          <div className="flex items-center gap-1.5 mt-2 flex-wrap">
                                            {scene.departments.map((d) => (
                                              <span key={d.dept} className="text-[10px] px-2 py-0.5 rounded-full border"
                                                style={{ color: DEPT_COLOR[d.dept] || "#6B6B6B", borderColor: `${DEPT_COLOR[d.dept] || "#6B6B6B"}40`, backgroundColor: `${DEPT_COLOR[d.dept] || "#6B6B6B"}12` }}>
                                                {d.dept} ({d.items.length})
                                              </span>
                                            ))}
                                          </div>
                                        </div>
                                        <div className="flex-shrink-0 w-24 flex flex-col items-center justify-center px-3 py-3 border-l border-[#1E1E1E] gap-1">
                                          <span className="text-[#FAFAFA] text-sm font-semibold tabular-nums">{scene.pages}</span>
                                          <span className="text-[#4A4A4A] text-[10px]">págs.</span>
                                          <ChevronRight className={`w-3.5 h-3.5 text-[#4A4A4A] mt-1 transition-transform ${isSceneExpanded ? "rotate-90" : ""}`} />
                                        </div>
                                      </button>

                                      {/* Scene dept editor */}
                                      {isSceneExpanded && (
                                        <div className="bg-[#0D0D0D] border-t border-[#1E1E1E] px-5 py-4">
                                          <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8">
                                            {scene.departments.map((dEntry) => (
                                              <TagEditor
                                                key={dEntry.dept}
                                                dept={dEntry.dept}
                                                items={dEntry.items}
                                                color={DEPT_COLOR[dEntry.dept] || "#6B6B6B"}
                                                onUpdate={(newItems) => updateDeptItems(scene.number, dEntry.dept, newItems)}
                                                onRemoveDept={() => removeDept(scene.number, dEntry.dept)}
                                              />
                                            ))}
                                          </div>

                                          {/* Add department */}
                                          <div className="mt-3 pt-3 border-t border-[#1A1A1A]">
                                            {addDeptScene === scene.number ? (
                                              <div className="flex items-center gap-2">
                                                <select
                                                  value={newDeptName}
                                                  onChange={(e) => setNewDeptName(e.target.value)}
                                                  className="flex-1 px-3 py-1.5 bg-[#0A0A0A] border border-[#7B5FCF] rounded text-[#FAFAFA] text-xs focus:outline-none"
                                                >
                                                  <option value="">Selecciona departamento…</option>
                                                  {ALL_DEPTS.filter((d) => !usedDeptNames.includes(d.name)).map((d) => (
                                                    <option key={d.name} value={d.name}>{d.name}</option>
                                                  ))}
                                                </select>
                                                <button onClick={() => addDept(scene.number)}
                                                  className="px-3 py-1.5 bg-[#7B5FCF] hover:bg-[#6a4eb8] text-white text-xs rounded transition-colors">
                                                  Agregar
                                                </button>
                                                <button onClick={() => { setAddDeptScene(null); setNewDeptName(""); }}
                                                  className="p-1.5 text-[#4A4A4A] hover:text-[#FAFAFA] transition-colors">
                                                  <X className="w-3.5 h-3.5" />
                                                </button>
                                              </div>
                                            ) : (
                                              <button
                                                onClick={() => setAddDeptScene(scene.number)}
                                                className="flex items-center gap-1.5 text-[#4A4A4A] hover:text-[#7B5FCF] text-xs border border-dashed border-[#2A2A2A] hover:border-[#7B5FCF] rounded-lg px-3 py-1.5 transition-all"
                                              >
                                                <Plus className="w-3 h-3" />
                                                Agregar departamento
                                              </button>
                                            )}
                                          </div>
                                        </div>
                                      )}
                                    </div>
                                  );
                                })}
                              </div>
                            </div>
                          ))}

                          <div className="px-5 py-3 bg-[#0A0A0A] border-t border-[#2A2A2A] flex items-center justify-between">
                            <span className="text-[#4A4A4A] text-xs">Fin Día #{day.dayNumber}</span>
                            <span className="text-[#6B6B6B] text-xs">Total: <span className="text-[#FAFAFA] font-medium">{day.totalPages}</span> págs.</span>
                          </div>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}
