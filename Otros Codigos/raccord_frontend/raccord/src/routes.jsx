import { createBrowserRouter } from "react-router-dom";
import LoginScreen from "./screen/LoginScreen";
import TwoFactorScreen from "./screen/TwoFactorScreen";
import ForgotPasswordScreen from "./screen/ForgotPasswordScreen";
import ProjectRegistrationScreen from "./screen/ProjectRegistrationScreen";
import ProjectSelectionScreen from "./screen/ProjectSelectionScreen";
import ProjectDashboardScreen from "./screen/ProjectDashboardScreen";
import ProfileScreen from "./screen/ProfileScreen";
import DashboardScreen from "./screen/DashboardScreen";
import LandingScreen from "./screen/LandingScreen";
import RolesScreen from "./screen/RolesScreen";
import ProtectedRoute from "./screen/ProtectedRoute";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: LandingScreen,
  },
  {
    path: "/login",
    Component: LoginScreen,
  },

  {
    path: "/verificacion",
    element: <ProtectedRoute><TwoFactorScreen /></ProtectedRoute>,
  },

  {
    path: "/recuperar-acceso",
    Component: ForgotPasswordScreen,
  },
  {
    path: "/registro-proyecto",
    element: <ProtectedRoute><ProjectRegistrationScreen /></ProtectedRoute>,
  },
  {
    path: "/seleccion-proyecto",
    element: <ProtectedRoute><ProjectSelectionScreen /></ProtectedRoute>,
  },
  {
    path: "/proyecto-dashboard",
    element: <ProtectedRoute><ProjectDashboardScreen /></ProtectedRoute>,
  },
  {
    path: "/perfil",
    element: <ProtectedRoute><ProfileScreen /></ProtectedRoute>,
  },
  {
    path: "/dashboard",
    element: <ProtectedRoute><DashboardScreen /></ProtectedRoute>,
  },
  {
    path: "/roles",
    element: <ProtectedRoute><RolesScreen /></ProtectedRoute>,
  },
]);