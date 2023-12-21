import AboutUs from "@/views/AboutUs";
import Dashboard from "@/views/Dashboard";
import Homepage from "@/views/Homepage";
import Login from "@/views/Login";
import SignUp from "@/views/SignUp";

type MAIN_PAGE_ROUTES_ITEM = {
  name: string;
  url: string;
  component: JSX.Element;
};

export const MAIN_PAGE_ROUTES: MAIN_PAGE_ROUTES_ITEM[] = [
  {
    name: "Homepage",
    url: "/",
    component: <Homepage />,
  },
  {
    name: "Dashboard",
    url: "/dashboard",
    component: <Dashboard />,
  },
  {
    name: "About Us",
    url: "/about-us",
    component: <AboutUs />,
  }
];

export const AUTH_ROUTES: MAIN_PAGE_ROUTES_ITEM[] = [
  {
    name: "Login",
    url: "/login",
    component: <Login />,
  },
  {
    name: "Sign Up",
    url: "/sign-up",
    component: <SignUp />,
  },
];