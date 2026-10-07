import { useState } from "react";
import { useLocation, useNavigate } from "react-router";
import {
  ArrowLeft, FileDown, Filter, Sun, Moon, Sunrise, Sunset,
  ChevronDown, ChevronRight, Clapperboard, Users, Zap, Camera,
  Shirt, Sparkles, Car, PawPrint, Wrench, Volume2, Video, Swords,
  AlertTriangle, UserPlus, Eye, Menu, User, Globe, LogOut
} from "lucide-react";
import logo from "../../imports/Logo_Negativo.png";

type TimeOfDay = "Day" | "Night" | "Dawn" | "Evening";

interface SceneDepts {
  cast: string[];
  props?: string[];
  extras?: string;
  bits?: string;
  stunts?: string;
  sfx?: string;
  vfx?: string;
  weapons?: string;
  vehicles?: string;
  animals?: string;
  art?: string;
  makeup?: string;
  makeupFX?: string;
  wardrobe?: string;
  camera?: string;
  sound?: string;
  notes?: string;
  additionalCrew?: string;
}

interface SceneEntry {
  number: string;
  intExt: "INT" | "EXT" | "INT/EXT";
  locationDetail: string;
  timeOfDay: TimeOfDay;
  pages: string;
  synopsis: string;
  depts: SceneDepts;
}

interface LocationGroup {
  locationName: string;
  scenes: SceneEntry[];
}

interface ShootDay {
  dayNumber: number;
  date: string;
  city: string;
  callTime: string;
  wrapTime: string;
  totalPages: string;
  generalNotes?: string;
  locationGroups: LocationGroup[];
}

interface Week {
  weekNumber: number;
  days: ShootDay[];
}

const TIME_CONFIG: Record<TimeOfDay, { label: string; color: string; icon: React.FC<{ className?: string }> }> = {
  Day:     { label: "Día",       color: "#F2A341", icon: Sun },
  Night:   { label: "Noche",     color: "#4A7FA5", icon: Moon },
  Dawn:    { label: "Amanecer",  color: "#7B5FCF", icon: Sunrise },
  Evening: { label: "Atardecer", color: "#E67E5C", icon: Sunset },
};

interface DeptRow {
  key: keyof SceneDepts;
  label: string;
  icon: React.FC<{ className?: string }>;
  color: string;
}

const DEPT_ROWS: DeptRow[] = [
  { key: "cast",           label: "Elenco",                icon: Users,         color: "#0B4F8A" },
  { key: "props",          label: "Props",                 icon: Wrench,        color: "#6B6B6B" },
  { key: "extras",         label: "Extras / BG",           icon: UserPlus,      color: "#6B6B6B" },
  { key: "bits",           label: "Bits",                  icon: Eye,           color: "#6B6B6B" },
  { key: "stunts",         label: "Stunts",                icon: Zap,           color: "#C64545" },
  { key: "sfx",            label: "SFX",                   icon: Sparkles,      color: "#E67E5C" },
  { key: "vfx",            label: "VFX",                   icon: Video,         color: "#7B5FCF" },
  { key: "weapons",        label: "Armas",                 icon: Swords,        color: "#C64545" },
  { key: "vehicles",       label: "Vehículos",             icon: Car,           color: "#6B6B6B" },
  { key: "animals",        label: "Animales",              icon: PawPrint,      color: "#3d9970" },
  { key: "art",            label: "Arte / Dir. de arte",   icon: Camera,        color: "#6B6B6B" },
  { key: "makeup",         label: "Maquillaje / Pelo",     icon: Sparkles,      color: "#6B6B6B" },
  { key: "makeupFX",       label: "Maquillaje FX",         icon: AlertTriangle, color: "#C64545" },
  { key: "wardrobe",       label: "Vestuario",             icon: Shirt,         color: "#6B6B6B" },
  { key: "camera",         label: "Cámara",                icon: Camera,        color: "#0B4F8A" },
  { key: "sound",          label: "Sonido",                icon: Volume2,       color: "#0B4F8A" },
  { key: "additionalCrew", label: "Crew Adicional",        icon: Users,         color: "#6B6B6B" },
  { key: "notes",          label: "Notas",                 icon: AlertTriangle, color: "#F2A341" },
];

const planData: Week[] = [
  {
    weekNumber: 1,
    days: [
      {
        dayNumber: 1,
        date: "Lunes, 15 de Septiembre 2026",
        city: "Valle del Cauca",
        callTime: "5:30 AM",
        wrapTime: "7:00 PM",
        totalPages: "4 6/8",
        generalNotes: "Confirmar acceso a Finca El Paraíso con dueño 48h antes. Generador propio requerido.",
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
                synopsis: "Lucía despierta antes del amanecer. Encuentra la carta que lo cambia todo.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO"],
                  props: ["Carta sellada con lacre rojo", "Vela casi consumida", "Baúl de madera colonial", "Cama de hierro forjado"],
                  sfx: "Niebla exterior filtrada por ventana · Brisa suave",
                  sound: "Silencio campestre · Aves nocturnas cediendo al amanecer",
                  camera: "Trípode · Plano secuencia 2 min sin cortes · Lente 35mm Zeiss",
                  art: "Cabaña época años 50 · Cuadros religiosos · Flores secas",
                  makeup: "Lucía: sin maquillaje, cabello suelto, aspecto de recién despertada",
                  wardrobe: "Camisón de algodón blanco · Chal de lana",
                  notes: "Ventana de luz mágica 5:15-5:45 AM. Tener cámara lista a las 5:00 AM.",
                },
              },
              {
                number: "2",
                intExt: "INT/EXT",
                locationDetail: "CABAÑA-PORCHE TRASERO",
                timeOfDay: "Dawn",
                pages: "4/8",
                synopsis: "Lucía y Doña Carmen intercambian pocas palabras. El silencio lo dice todo.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO", "3. DOÑA CARMEN"],
                  extras: "Peones de finca en fondo (8)",
                  props: ["Taza de tinto humeante", "Mecedora de madera"],
                  sound: "Gallos · Ambiente rural temprano",
                  camera: "Steady lateral + plano fijo para contraplano",
                  wardrobe: "Doña Carmen: delantal de flores, trenza canosa",
                  makeup: "Doña Carmen: edad avanzada, manos trabajadas",
                  art: "Porche con enredaderas · Orquídeas naturales",
                },
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
                synopsis: "Durante la fiesta de la hacienda, Lucía y Sebastián se encuentran por primera vez frente a la fuente.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO", "2. SEBASTIÁN MORA"],
                  extras: "Invitados de fiesta en jardín (30) · 8 parejas bailando",
                  bits: "Mozo con bandeja · Músico que observa la escena",
                  props: ["Copa de champaña (prop líquido inocuo)", "Pañuelo bordado con iniciales", "Faroles de papel encendidos"],
                  sfx: "Música diegética de cuerda (cuarteto en set) · Cigarros humeantes (prop)",
                  sound: "Música cuarteto real · Cuchicheo de invitados · Fuente de agua",
                  camera: "Dolly circular alrededor de la fuente · Plano detalle manos",
                  art: "Jardín colonial iluminado con velas y faroles · Fuente de piedra con agua real",
                  wardrobe: "Lucía: vestido verde esmeralda años 50 / Sebastián: traje oscuro de lino",
                  makeup: "Lucía: labios rojos, cabello recogido / Sebastián: gomina, afeitado perfecto",
                  notes: "Iluminación: prioridad a luz de velas reales + relleno suave LED ámbar.",
                },
              },
              {
                number: "9",
                intExt: "EXT",
                locationDetail: "JARDÍN-CORREDOR DE ÁRBOLES",
                timeOfDay: "Night",
                pages: "4/8",
                synopsis: "Sebastián y Andrés se confrontan entre los árboles. Las amenazas quedan claras.",
                depts: {
                  cast: ["2. SEBASTIÁN MORA", "4. ANDRÉS VALLEJO"],
                  stunts: "Forcejeo contenido entre árboles · Sin doble · Coreografía aprobada",
                  camera: "Cámara en mano tensa · Lente 50mm",
                  sound: "Hojas, viento, respiración",
                  additionalCrew: "Coordinador de stunts presente",
                },
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
        wrapTime: "6:30 PM",
        totalPages: "5 2/8",
        generalNotes: "Día de exteriores en altura. Ropa de abrigo para todo el equipo. Vía de acceso estrecha: máximo camionetas.",
        locationGroups: [
          {
            locationName: "Sendero de la Montaña – Finca El Paraíso",
            scenes: [
              {
                number: "3",
                intExt: "EXT",
                locationDetail: "SENDERO-CRUCE DEL RÍO",
                timeOfDay: "Dawn",
                pages: "2 4/8",
                synopsis: "Lucía y Petra huyen con lo que pueden cargar. El río es el único camino.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO", "5. PETRA SUÁREZ"],
                  stunts: "Cruce de río con corriente moderada · Doble para Lucía en toma lejana · Coord: Felipe Cárdenas",
                  sfx: "Niebla baja (máquinas de vapor × 2) · Salpicadura controlada",
                  sound: "Río real · Pájaros temprano · Pisadas urgentes",
                  camera: "Aéreo drone bajo + steadicam en orilla · Underwater housing para toma de pies",
                  wardrobe: "Ropa de época sencilla, mojada en set desde toma 2 · 3 mudas por artista",
                  makeup: "Efecto mojado y cansancio · Seguimiento continuo",
                  props: ["Bulto de lona con objetos", "Mapa dibujado a mano", "Lámpara de petróleo"],
                  extras: "Arrieros a caballo en fondo lejano (4)",
                  additionalCrew: "Seguridad acuática certificada (2) · Bote de rescate en aguas abajo",
                },
              },
              {
                number: "5",
                intExt: "EXT",
                locationDetail: "CIMA-MIRADOR NATURAL",
                timeOfDay: "Dawn",
                pages: "1",
                synopsis: "Sola en la cima, Lucía lee la carta completa. Por primera vez comprende.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO"],
                  sfx: "Viento alto real · Sin intervención",
                  vfx: "Extensión de amanecer en horizonte (comp post) · Cóndores digitales opcionales",
                  sound: "Viento puro · Sin música",
                  camera: "Drone circular amplio + plano fijo en trípode · Lente 85mm",
                  makeup: "Continuidad mojado de Sc. 3 + barro ligero",
                  notes: "Ventana de luz: 25 minutos máximos. Equipo mínimo en cima. 1 PA, 1 DP, 1 actriz.",
                },
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
                synopsis: "La cena más tensa de la familia. Las despedidas no se dicen, se sienten.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO", "2. SEBASTIÁN MORA", "3. DOÑA CARMEN", "4. ANDRÉS VALLEJO"],
                  extras: "Sirvientes de fondo (5)",
                  props: ["Mesa colonial con vajilla de loza", "Telegrama doblado junto al plato", "Retrato familiar al fondo", "Candelabros de plata"],
                  sfx: "Lluvia exterior suave (rig en ventanas laterales)",
                  sound: "Lluvia · Cubiertos · Silencio incómodo",
                  camera: "4 cámaras en L · Master + 3 individuales sin corte",
                  art: "Salón época impecable · Flores naturales en centro de mesa",
                  wardrobe: "Todos: ropa de noche formal según personaje · Continuidad cena",
                  makeup: "Lucía: tensa, ojos levemente rojos · Doña Carmen: dignidad contenida",
                  notes: "Rig de lluvia en ventanas: confirmar 4h antes con SFX.",
                },
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
        wrapTime: "5:00 PM",
        totalPages: "3 4/8",
        generalNotes: "Coordinación con autoridades locales para cierre parcial plaza 8:00-12:00. Respetar día de mercado indígena.",
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
                synopsis: "Lucía se topa con el Coronel Ríos. La conversación es una advertencia velada.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO", "6. CORONEL RÍOS"],
                  extras: "Feligreses y marchantes (45) · 6 en primer plano con trajes guambianos",
                  props: ["Carruaje de época (prop arte, sin motor)", "Periódico local 1952", "Bastón del Coronel"],
                  sfx: "Campanadas de iglesia (playback sincronizado)",
                  sound: "Ambiente plaza viva · Voces indígenas en fondo",
                  camera: "Steady + grúa pequeña para aéreo de plaza",
                  art: "Sin intervención · Arquitectura colonial real · Aprovecha mercado real",
                  wardrobe: "Coronel: uniforme militar de época / Lucía: vestido de viajera",
                  vehicles: "Carruaje prop (tracción animal, caballo entrenado)",
                  animals: "1 caballo percherón entrenado para set",
                },
              },
              {
                number: "14",
                intExt: "EXT",
                locationDetail: "PLAZA-PUESTO DE MERCADO",
                timeOfDay: "Day",
                pages: "2 2/8",
                synopsis: "Lucía recibe el mensaje de Petra a través de la Niña Isabel. El plan comienza.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO", "5. PETRA SUÁREZ", "7. NIÑA ISABEL"],
                  extras: "Vendedores y compradores (25)",
                  bits: "Vendedora de flores con frase · Anciano que escucha sin entender",
                  props: ["Flores frescas (varias canastas)", "Cesta de mimbre con doble fondo", "Monedas de época"],
                  stunts: "Empujón en multitud · Caída leve de Lucía al suelo",
                  sound: "Mercado vivo · Regateo · Música de marimba lejana",
                  camera: "Cámara en mano sucia + plano fijo para reacción niña",
                  wardrobe: "Petra: disfraz de vendedora / Isabel: vestido floral infantil",
                  makeup: "Isabel: maquillaje mínimo, apariencia natural",
                  additionalCrew: "1 tutor para menor de edad en set",
                },
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
        wrapTime: "9:00 PM",
        totalPages: "6",
        generalNotes: "Tres locaciones en Cali. Camión de producción estaciona en Av. Colombia. Catering en segundo camión.",
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
                synopsis: "Lucía y Sebastián se reencuentran en el mercado. La tensión los delata.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO", "2. SEBASTIÁN MORA"],
                  extras: "Comerciantes y compradores (60)",
                  props: ["Paquete envuelto en papel kraft", "Revólver de época (muda, sin munición)", "Maletín de cuero"],
                  sound: "Ambiente mercado caleño · Pregones · Cumbia lejana",
                  camera: "Steady en pasillo + 2 cámaras de cobertura ocultas",
                  art: "Mercado Alameda sin intervención · Colorido natural",
                  wardrobe: "Ambos: ropa de ciudad años 50 · Sombreros",
                  weapons: "Revólver prop mudo (registro en set, custodia armería)",
                },
              },
              {
                number: "21",
                intExt: "EXT",
                locationDetail: "MERCADO-CALLEJÓN LATERAL",
                timeOfDay: "Day",
                pages: "2/8",
                synopsis: "Andrés y el Coronel finalizan su pacto. El traidor queda sellado.",
                depts: {
                  cast: ["4. ANDRÉS VALLEJO", "6. CORONEL RÍOS"],
                  stunts: "Intercambio de documentos bajo presión · Manotazo sobre pared",
                  camera: "Cámara en mano · Lente 28mm angulado",
                  sound: "Eco de callejón · Pasos acelerados fuera de cámara",
                  wardrobe: "Continuidad Sc. 18 para ambos",
                },
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
                synopsis: "El Coronel Ríos le ofrece a Lucía una salida. Ella escucha sin comprometerse.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO", "6. CORONEL RÍOS"],
                  extras: "Paseantes vespertinos (20)",
                  props: ["Maletín de cuero marrón", "Fotografías comprometedoras (prop arte)", "Cigarrillo de época"],
                  sound: "Bocinas de carros de época · Viento suave · Palomas",
                  camera: "Dolly lento atrás en diálogo · Golden hour natural",
                  art: "Plaza sin intervención · Luz atardecer aprovechada",
                  wardrobe: "Lucía: abrigo crema / Coronel: uniforme sin gorra",
                  notes: "Hora dorada: 5:40-6:10 PM. Tener listo a las 5:20 PM.",
                },
              },
              {
                number: "26",
                intExt: "EXT",
                locationDetail: "PLAZA-ACCESO NORTE",
                timeOfDay: "Night",
                pages: "2 2/8",
                synopsis: "La trampa se activa. Los tres convergen en la plaza y todo se rompe.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO", "2. SEBASTIÁN MORA", "4. ANDRÉS VALLEJO"],
                  stunts: "Persecución a pie hasta esquina · Caída controlada Andrés · Forcejeo doble",
                  sfx: "Lluvia artificial (rig de tubería 20m) · Truenos (playback) · Humo ambiental",
                  vfx: "Relámpago en fondo de fachada (comp post)",
                  sound: "Truenos reales + diseñados · Lluvia rig · Pasos",
                  camera: "3 cámaras simultáneas · 1 en crane · 120fps en caída",
                  makeupFX: "Sebastián: herida ceja · Lucía: rasguño mano",
                  wardrobe: "Todos: versión destrucción · Pre-mojado antes de toma",
                  additionalCrew: "Médico en set · PA × 4 en cada esquina de plaza",
                  notes: "Permisos Alcaldía Cali para uso de agua en vía pública. Confirmar 72h antes.",
                },
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
        wrapTime: "6:00 PM",
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
                synopsis: "Lucía y Petra planean la última jugada. La máquina de escribir no para.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO", "5. PETRA SUÁREZ"],
                  props: ["Máquina de escribir Olivetti Lettera 22", "Cartas apiladas y revisadas", "Maleta abierta a medio empacar", "Mapa marcado con rutas"],
                  sfx: "Ventilador de techo girando (práctica) · Clic de máquina real",
                  sound: "Máquina de escribir · Tráfico lejano de calle caleña",
                  camera: "Planos medios + macro detalles de teclas · Lente 50mm",
                  art: "Habitación hotel años 50 · Documentos esparcidos · Luz de persiana",
                  wardrobe: "Lucía: bata de hotel / Petra: ropa de calle lista para salir",
                  makeup: "Ambas: aspecto de noche sin dormir",
                },
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
                synopsis: "El reencuentro que nadie esperaba. Doña Carmen lleva la verdad consigo.",
                depts: {
                  cast: ["1. LUCÍA CAMACHO", "2. SEBASTIÁN MORA", "3. DOÑA CARMEN"],
                  extras: "Feligreses en bancas (35) · 5 en primeros planos",
                  bits: "Sacerdote que pasa · Monaguillo con incensario",
                  props: ["Velas encendidas (prop gas seguro)", "Rosario antiguo de nácar", "Sobre con sello de cera rojo", "Biblia con páginas marcadas"],
                  sfx: "Eco natural de la iglesia aprovechado · Incienso real",
                  sound: "Eco de pasos en piedra · Órgano diegético (organista en set) · Silencio de templo",
                  camera: "Dolly en rieles 25m hacia el altar · Planos de detalle manos y objeto",
                  art: "Iglesia real sin intervención · Velas prácticas añadidas · Flores blancas en altares",
                  wardrobe: "Todos: ropa de misa años 50 · Doña Carmen: mantilla negra",
                  makeup: "Doña Carmen: lágrimas contenidas (glicerina en espera)",
                  notes: "Coordinación con párroco para horario fuera de misas. Silencio de equipo obligatorio.",
                },
              },
            ],
          },
        ],
      },
    ],
  },
];

function hasDeptValue(depts: SceneDepts, key: keyof SceneDepts): boolean {
  const val = depts[key] as string | string[] | undefined;
  if (!val) return false;
  if (Array.isArray(val)) return val.length > 0;
  return val.trim().length > 0;
}

function getDeptValue(depts: SceneDepts, key: keyof SceneDepts): string {
  const val = depts[key] as string | string[] | undefined;
  if (!val) return "";
  if (Array.isArray(val)) return val.join("\n");
  return val;
}

function generatePDFHTML(data: Week[], projectName: string): string {
  const timeLabels: Record<TimeOfDay, string> = {
    Day: "Día", Night: "Noche", Dawn: "Amanecer", Evening: "Atardecer",
  };

  const deptLabels: Partial<Record<keyof SceneDepts, string>> = {
    cast: "ELENCO", props: "PROPS", extras: "EXTRAS / BG", bits: "BITS",
    stunts: "STUNTS", sfx: "SFX", vfx: "VFX", weapons: "ARMAS",
    vehicles: "VEHÍCULOS", animals: "ANIMALES", art: "ARTE",
    makeup: "MAQUILLAJE / PELO", makeupFX: "MAQUILLAJE FX", wardrobe: "VESTUARIO",
    camera: "CÁMARA", sound: "SONIDO", additionalCrew: "CREW ADICIONAL", notes: "NOTAS",
  };

  let body = "";
  for (const week of data) {
    body += `<div class="week-header">SEMANA ${week.weekNumber}</div>`;
    for (const day of week.days) {
      body += `<div class="day-header">
        <strong>DÍA ${day.dayNumber}</strong> &nbsp;·&nbsp; ${day.date} &nbsp;·&nbsp; ${day.city}
        &nbsp;·&nbsp; Llamado: ${day.callTime} – Wrap: ${day.wrapTime} &nbsp;·&nbsp; Total: ${day.totalPages} págs.
      </div>`;
      if (day.generalNotes) {
        body += `<div class="day-notes">⚠ ${day.generalNotes}</div>`;
      }
      for (const group of day.locationGroups) {
        body += `<div class="loc-header">${group.locationName}</div>`;
        for (const sc of group.scenes) {
          const activeDepts = DEPT_ROWS.filter((d) => hasDeptValue(sc.depts, d.key));
          body += `<div class="scene-block">
            <div class="scene-header">
              <span class="scene-num">Sc. ${sc.number}</span>
              <span class="badge">${sc.intExt}</span>
              <span class="scene-loc">${sc.locationDetail}</span>
              <span class="scene-time">${timeLabels[sc.timeOfDay]}</span>
              <span class="scene-pages">${sc.pages} págs.</span>
            </div>
            <div class="synopsis">${sc.synopsis}</div>
            <table class="dept-table">
              ${activeDepts.map((d) => `<tr>
                <td class="dept-label">${deptLabels[d.key] || d.label}</td>
                <td class="dept-value">${getDeptValue(sc.depts, d.key).replace(/\n/g, "<br>")}</td>
              </tr>`).join("")}
            </table>
          </div>`;
        }
      }
      body += `<div class="end-day">Fin Día #${day.dayNumber} &nbsp;·&nbsp; Total páginas: <strong>${day.totalPages}</strong></div>`;
    }
  }

  return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Plan de Rodaje – ${projectName}</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: Arial, Helvetica, sans-serif; font-size: 9px; color: #111; background: #fff; }
  .page-header { border-bottom: 2px solid #111; padding-bottom: 8px; margin-bottom: 14px; display: flex; justify-content: space-between; align-items: flex-end; }
  .page-header h1 { font-size: 16px; font-weight: 700; letter-spacing: 0.05em; }
  .page-header .meta { font-size: 8px; color: #555; text-align: right; line-height: 1.6; }
  .week-header { background: #111; color: #fff; font-weight: 700; font-size: 10px; letter-spacing: 0.1em; padding: 5px 8px; margin-top: 14px; text-transform: uppercase; page-break-before: auto; }
  .day-header { background: #333; color: #fff; font-size: 8.5px; padding: 4px 8px; }
  .day-notes { background: #fff8e1; border-left: 3px solid #f5a623; color: #5a3e00; font-size: 8px; padding: 3px 8px; }
  .loc-header { background: #888; color: #eee; font-size: 8px; font-style: italic; padding: 3px 8px; }
  .scene-block { border: 1px solid #ddd; margin: 4px 0; page-break-inside: avoid; }
  .scene-header { background: #f0f0f0; display: flex; align-items: center; gap: 8px; padding: 4px 8px; flex-wrap: wrap; }
  .scene-num { font-weight: 700; font-size: 11px; }
  .badge { font-family: monospace; border: 1px solid #999; border-radius: 2px; padding: 1px 4px; font-size: 7.5px; }
  .scene-loc { font-weight: 600; flex: 1; }
  .scene-time { color: #555; }
  .scene-pages { font-weight: 700; margin-left: auto; }
  .synopsis { font-style: italic; color: #444; padding: 3px 8px; border-bottom: 1px solid #eee; font-size: 8.5px; }
  .dept-table { width: 100%; border-collapse: collapse; }
  .dept-table td { padding: 2px 8px; border-bottom: 1px solid #f0f0f0; vertical-align: top; }
  .dept-label { font-weight: 700; font-size: 7.5px; letter-spacing: 0.06em; color: #444; width: 110px; white-space: nowrap; }
  .dept-value { font-size: 8.5px; }
  .end-day { background: #f5f5f5; color: #666; font-style: italic; font-size: 8px; padding: 3px 8px; margin-bottom: 4px; text-align: right; }
  .footer { margin-top: 14px; border-top: 1px solid #ccc; padding-top: 6px; display: flex; justify-content: space-between; font-size: 7.5px; color: #888; }
  @media print {
    body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .week-header { page-break-before: auto; }
    .scene-block { page-break-inside: avoid; }
  }
</style>
</head>
<body>
<div class="page-header">
  <div>
    <div style="font-size:8px;text-transform:uppercase;letter-spacing:0.12em;color:#555;margin-bottom:3px;">Plan de Rodaje</div>
    <h1>${projectName}</h1>
  </div>
  <div class="meta">
    Semanas: ${data.length} &nbsp;·&nbsp; Días de rodaje: ${data.reduce((a, w) => a + w.days.length, 0)}<br>
    Escenas totales: ${data.reduce((a, w) => a + w.days.reduce((a2, d) => a2 + d.locationGroups.reduce((a3, g) => a3 + g.scenes.length, 0), 0), 0)}<br>
    Generado: ${new Date().toLocaleDateString("es-CO", { day: "2-digit", month: "long", year: "numeric" })}
  </div>
</div>

${body}

<div class="footer">
  <span>Documento de uso interno. Confidencial. No distribuir sin autorización de producción.</span>
  <span>SFX = Efectos especiales &nbsp;·&nbsp; VFX = Efectos visuales &nbsp;·&nbsp; STN = Stunts &nbsp;·&nbsp; BG = Extras</span>
</div>
</body>
</html>`;
}

function downloadPDF(data: Week[], projectName: string) {
  const html = generatePDFHTML(data, projectName);
  const win = window.open("", "_blank", "width=900,height=700");
  if (!win) {
    alert("Permite ventanas emergentes para exportar el PDF.");
    return;
  }
  win.document.write(html);
  win.document.close();
  setTimeout(() => {
    win.focus();
    win.print();
  }, 600);
}

export default function PlanDeRodajeScreen() {
  const location = useLocation();
  const navigate = useNavigate();
  const projectName = location.state?.projectName || "Proyecto";

  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  const [selectedWeek, setSelectedWeek] = useState<number | "all">("all");
  const [selectedTime, setSelectedTime] = useState<TimeOfDay | "all">("all");
  const [expandedDays, setExpandedDays] = useState<Set<string>>(new Set(["1-1"]));
  const [expandedScenes, setExpandedScenes] = useState<Set<string>>(new Set());

  const menuOptions = [
    "Guión", "Crear Escenas", "Crear Personajes", "Crew List",
    "Plan de Rodaje", "Desglose", "Galería", "Roles",
  ];

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
    setExpandedDays((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const toggleScene = (key: string) => {
    setExpandedScenes((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const filtered = planData
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

  const allSceneKeys = filtered.flatMap((w) =>
    w.days.flatMap((d) =>
      d.locationGroups.flatMap((g) =>
        g.scenes.map((s) => `${w.weekNumber}-${d.dayNumber}-${s.number}`)
      )
    )
  );

  return (
    <div className="min-h-screen bg-[#0A0A0A]">
      {/* Header – matches other screens */}
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

          <h2 className="text-[#FAFAFA]">{projectName} – Plan de Rodaje</h2>

          <div className="flex items-center gap-3">
            <button
              onClick={() => downloadPDF(planData, projectName)}
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-[#E67E5C] hover:bg-[#d06b4a] text-white text-sm font-medium transition-colors"
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
          <h1 className="text-[#FAFAFA] text-2xl font-semibold tracking-wide mb-1">
            Plan de Rodaje
          </h1>
          <p className="text-[#6B6B6B] text-sm">
            {filtered.reduce((a, w) => a + w.days.length, 0)} días de rodaje ·{" "}
            {filtered.reduce((acc, w) => acc + w.days.reduce((a2, d) => a2 + d.locationGroups.reduce((a3, g) => a3 + g.scenes.length, 0), 0), 0)} escenas
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
              <button
                key={w}
                onClick={() => setSelectedWeek(w)}
                className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                  selectedWeek === w
                    ? "bg-[#E67E5C] text-white"
                    : "bg-[#2A2A2A] text-[#6B6B6B] hover:text-[#FAFAFA]"
                }`}
              >
                {w === "all" ? "Todas las semanas" : `Semana ${w}`}
              </button>
            ))}
          </div>

          <div className="w-px h-5 bg-[#2A2A2A]" />

          <div className="flex items-center gap-1">
            <button
              onClick={() => setSelectedTime("all")}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                selectedTime === "all"
                  ? "bg-[#2A2A2A] text-[#FAFAFA] ring-1 ring-[#4A4A4A]"
                  : "text-[#6B6B6B] hover:text-[#FAFAFA]"
              }`}
            >
              Todos
            </button>
            {(Object.entries(TIME_CONFIG) as [TimeOfDay, typeof TIME_CONFIG[TimeOfDay]][]).map(([key, cfg]) => {
              const Icon = cfg.icon;
              return (
                <button
                  key={key}
                  onClick={() => setSelectedTime(key)}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                    selectedTime === key ? "text-white" : "text-[#6B6B6B] hover:text-[#FAFAFA]"
                  }`}
                  style={selectedTime === key ? { backgroundColor: cfg.color } : {}}
                >
                  <Icon className="w-3 h-3" />
                  {cfg.label}
                </button>
              );
            })}
          </div>

          <div className="ml-auto flex items-center gap-2 text-xs text-[#6B6B6B]">
            <button
              onClick={() => setExpandedScenes(new Set(allSceneKeys))}
              className="hover:text-[#FAFAFA] transition-colors underline underline-offset-2"
            >
              Expandir todo
            </button>
            <span>·</span>
            <button
              onClick={() => setExpandedScenes(new Set())}
              className="hover:text-[#FAFAFA] transition-colors underline underline-offset-2"
            >
              Colapsar todo
            </button>
          </div>
        </div>

        {/* Data */}
        <div className="space-y-8">
          {filtered.map((week) => (
            <div key={week.weekNumber}>
              <div className="flex items-center gap-3 mb-4">
                <div className="bg-[#E67E5C] text-white text-xs font-bold px-3 py-1 rounded-full tracking-widest uppercase">
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
                      <button
                        onClick={() => toggleDay(dayKey)}
                        className="w-full flex items-center justify-between px-5 py-4 hover:bg-[#202020] transition-colors"
                      >
                        <div className="flex items-center gap-4">
                          <span className="text-[#E67E5C] font-bold text-lg">DÍA {day.dayNumber}</span>
                          <div className="w-px h-8 bg-[#2A2A2A]" />
                          <div className="text-left">
                            <p className="text-[#FAFAFA] font-medium text-sm">{day.date}</p>
                            <p className="text-[#6B6B6B] text-xs mt-0.5">
                              {day.city} · {day.callTime} – {day.wrapTime} · {day.totalPages} págs.
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="text-[#6B6B6B] text-xs">
                            {day.locationGroups.reduce((a, g) => a + g.scenes.length, 0)} escenas
                          </span>
                          <ChevronDown
                            className={`w-4 h-4 text-[#6B6B6B] transition-transform ${isExpanded ? "rotate-180" : ""}`}
                          />
                        </div>
                      </button>

                      {isExpanded && (
                        <div className="border-t border-[#2A2A2A]">
                          {day.generalNotes && (
                            <div className="px-5 py-3 bg-[#F2A341]/5 border-b border-[#F2A341]/20 flex items-start gap-2">
                              <AlertTriangle className="w-3.5 h-3.5 text-[#F2A341] flex-shrink-0 mt-0.5" />
                              <p className="text-[#F2A341] text-xs leading-relaxed">{day.generalNotes}</p>
                            </div>
                          )}

                          {day.locationGroups.map((group, gi) => (
                            <div key={gi} className={gi > 0 ? "border-t border-[#1E1E1E]" : ""}>
                              <div className="px-5 py-2.5 bg-[#141414] flex items-center gap-2">
                                <Camera className="w-3.5 h-3.5 text-[#4A4A4A]" />
                                <span className="text-[#6B6B6B] text-xs font-semibold tracking-widest uppercase">
                                  {group.locationName}
                                </span>
                              </div>

                              <div className="divide-y divide-[#1E1E1E]">
                                {group.scenes.map((scene) => {
                                  const timeCfg = TIME_CONFIG[scene.timeOfDay];
                                  const TimeIcon = timeCfg.icon;
                                  const sceneKey = `${week.weekNumber}-${day.dayNumber}-${scene.number}`;
                                  const isSceneExpanded = expandedScenes.has(sceneKey);
                                  const activeDepts = DEPT_ROWS.filter((d) => hasDeptValue(scene.depts, d.key));

                                  return (
                                    <div key={scene.number}>
                                      <button
                                        onClick={() => toggleScene(sceneKey)}
                                        className="w-full flex items-stretch hover:bg-[#1E1E1E] transition-colors text-left"
                                      >
                                        <div className="w-1 flex-shrink-0" style={{ backgroundColor: timeCfg.color }} />
                                        <div className="flex-shrink-0 w-16 flex flex-col items-center justify-center px-3 py-3 border-r border-[#1E1E1E]">
                                          <span className="text-[#FAFAFA] font-bold text-base leading-none">{scene.number}</span>
                                          <span className="text-[#4A4A4A] text-[10px] mt-0.5">Sc.</span>
                                        </div>
                                        <div className="flex-1 px-4 py-3 min-w-0">
                                          <div className="flex items-center gap-2 flex-wrap">
                                            <span className="text-[#6B6B6B] text-xs font-mono border border-[#2A2A2A] rounded px-1.5 py-0.5">
                                              {scene.intExt}
                                            </span>
                                            <span className="text-[#FAFAFA] text-sm font-medium">
                                              {scene.locationDetail}
                                            </span>
                                            <div
                                              className="flex items-center gap-1 text-xs px-2 py-0.5 rounded-full"
                                              style={{ color: timeCfg.color, backgroundColor: `${timeCfg.color}20` }}
                                            >
                                              <TimeIcon className="w-3 h-3" />
                                              <span>{timeCfg.label}</span>
                                            </div>
                                          </div>
                                          <p className="text-[#6B6B6B] text-xs mt-1.5 line-clamp-1 italic">
                                            {scene.synopsis}
                                          </p>
                                          <div className="flex items-center gap-1.5 mt-1.5 flex-wrap">
                                            {activeDepts.slice(0, 6).map((dept) => {
                                              const DIcon = dept.icon;
                                              return (
                                                <span key={dept.key} className="text-[10px] text-[#4A4A4A] flex items-center gap-0.5 border border-[#2A2A2A] rounded px-1.5 py-0.5">
                                                  <DIcon className="w-2.5 h-2.5" />
                                                  {dept.label}
                                                </span>
                                              );
                                            })}
                                            {activeDepts.length > 6 && (
                                              <span className="text-[10px] text-[#4A4A4A]">+{activeDepts.length - 6} más</span>
                                            )}
                                          </div>
                                        </div>
                                        <div className="flex-shrink-0 w-24 flex flex-col items-center justify-center px-3 py-3 border-l border-[#1E1E1E] gap-1">
                                          <span className="text-[#FAFAFA] text-sm font-semibold tabular-nums">{scene.pages}</span>
                                          <span className="text-[#4A4A4A] text-[10px]">págs.</span>
                                          <ChevronRight
                                            className={`w-3.5 h-3.5 text-[#4A4A4A] mt-1 transition-transform ${isSceneExpanded ? "rotate-90" : ""}`}
                                          />
                                        </div>
                                      </button>

                                      {isSceneExpanded && (
                                        <div className="bg-[#0D0D0D] border-t border-[#1E1E1E] px-5 py-4">
                                          <p className="text-[#6B6B6B] text-sm mb-4 leading-relaxed italic border-l-2 border-[#2A2A2A] pl-3">
                                            {scene.synopsis}
                                          </p>
                                          <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 divide-y divide-[#1A1A1A]">
                                            {activeDepts.map((dept) => {
                                              const DIcon = dept.icon;
                                              const val = getDeptValue(scene.depts, dept.key);
                                              return (
                                                <div key={dept.key} className="py-3 flex items-start gap-3">
                                                  <div
                                                    className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5"
                                                    style={{ backgroundColor: `${dept.color}18` }}
                                                  >
                                                    <DIcon className="w-3.5 h-3.5" style={{ color: dept.color }} />
                                                  </div>
                                                  <div className="flex-1 min-w-0">
                                                    <p className="text-[#4A4A4A] text-[10px] font-semibold tracking-widest uppercase mb-1">
                                                      {dept.label}
                                                    </p>
                                                    <div className="text-[#FAFAFA] text-xs leading-relaxed">
                                                      {val.split("\n").map((line, i) => <p key={i}>{line}</p>)}
                                                    </div>
                                                  </div>
                                                </div>
                                              );
                                            })}
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
                            <span className="text-[#6B6B6B] text-xs">
                              Total páginas: <span className="text-[#FAFAFA] font-medium">{day.totalPages}</span>
                            </span>
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

        {filtered.length === 0 && (
          <div className="text-center py-20 text-[#4A4A4A]">
            <Clapperboard className="w-10 h-10 mx-auto mb-3 opacity-30" />
            <p>No hay escenas con los filtros seleccionados.</p>
          </div>
        )}
      </main>
    </div>
  );
}
