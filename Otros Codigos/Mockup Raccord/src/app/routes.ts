import { createBrowserRouter } from "react-router";
import LoginScreen from "./screens/LoginScreen";
import TwoFactorScreen from "./screens/TwoFactorScreen";
import ForgotPasswordScreen from "./screens/ForgotPasswordScreen";
import ProjectRegistrationScreen from "./screens/ProjectRegistrationScreen";
import ProjectSelectionScreen from "./screens/ProjectSelectionScreen";
import ProjectDashboardScreen from "./screens/ProjectDashboardScreen";
import ProfileScreen from "./screens/ProfileScreen";
import ScriptListScreen from "./screens/ScriptListScreen";
import ScriptViewScreen from "./screens/ScriptViewScreen";
import SceneListScreen from "./screens/SceneListScreen";
import CreateSceneScreen from "./screens/CreateSceneScreen";
import SceneDetailScreen from "./screens/SceneDetailScreen";
import ScenePhotosScreen from "./screens/ScenePhotosScreen";
import GalleryScreen from "./screens/GalleryScreen";
import CrewListScreen from "./screens/CrewListScreen";
import CreateCharacterScreen from "./screens/CreateCharacterScreen";
import DashboardScreen from "./screens/DashboardScreen";
import DesgloseScreen from "./screens/DesgloseScreen";
import PlanDeRodajeScreen from "./screens/PlanDeRodajeScreen";
import RolesScreen from "./screens/RolesScreen";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: LoginScreen,
  },
  {
    path: "/verificacion",
    Component: TwoFactorScreen,
  },
  {
    path: "/recuperar-acceso",
    Component: ForgotPasswordScreen,
  },
  {
    path: "/registro-proyecto",
    Component: ProjectRegistrationScreen,
  },
  {
    path: "/seleccion-proyecto",
    Component: ProjectSelectionScreen,
  },
  {
    path: "/proyecto-dashboard",
    Component: ProjectDashboardScreen,
  },
  {
    path: "/perfil",
    Component: ProfileScreen,
  },
  {
    path: "/guiones",
    Component: ScriptListScreen,
  },
  {
    path: "/guion-detalle",
    Component: ScriptViewScreen,
  },
  {
    path: "/escenas",
    Component: SceneListScreen,
  },
  {
    path: "/crear-escena",
    Component: CreateSceneScreen,
  },
  {
    path: "/escena-detalle",
    Component: SceneDetailScreen,
  },
  {
    path: "/escena-fotos",
    Component: ScenePhotosScreen,
  },
  {
    path: "/galeria",
    Component: GalleryScreen,
  },
  {
    path: "/crew-list",
    Component: CrewListScreen,
  },
  {
    path: "/crear-personaje",
    Component: CreateCharacterScreen,
  },
  {
    path: "/dashboard",
    Component: DashboardScreen,
  },
  {
    path: "/desglose",
    Component: DesgloseScreen,
  },
  {
    path: "/plan-de-rodaje",
    Component: PlanDeRodajeScreen,
  },
  {
    path: "/roles",
    Component: RolesScreen,
  },
]);
