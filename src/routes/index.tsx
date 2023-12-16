import AboutUs from "@/views/AboutUs";
import Dashboard from "@/views/Dashboard";
import Homepage from "@/views/Homepage";

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
  },
];
