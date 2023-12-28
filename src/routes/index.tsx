import { Suspense, lazy } from "react";

const AboutUs = lazy(() => import("@/views/AboutUs"));
const Dashboard = lazy(() => import("@/views/Dashboard"));
const Homepage = lazy(() => import("@/views/Homepage"));
const Login = lazy(() => import("@/views/Login"));
const SignUp = lazy(() => import("@/views/SignUp"));

type MAIN_PAGE_ROUTES_ITEM = {
  name: string;
  url: string;
  component: JSX.Element;
};

const SuspenseWithLoader = ({
  children,
}: {
  children: React.ReactElement;
}): JSX.Element => <Suspense>{children}</Suspense>;

export const MAIN_PAGE_ROUTES: MAIN_PAGE_ROUTES_ITEM[] = [
  {
    name: "Homepage",
    url: "/",
    component: (
      <SuspenseWithLoader>
        <Homepage />
      </SuspenseWithLoader>
    ),
  },
  {
    name: "Dashboard",
    url: "/dashboard",
    component: (
      <SuspenseWithLoader>
        <Dashboard />
      </SuspenseWithLoader>
    ),
  },
  {
    name: "About Us",
    url: "/about-us",
    component: (
      <SuspenseWithLoader>
        <AboutUs />
      </SuspenseWithLoader>
    ),
  },
];

export const AUTH_ROUTES: MAIN_PAGE_ROUTES_ITEM[] = [
  {
    name: "Login",
    url: "/login",
    component: (
      <SuspenseWithLoader>
        <Login />
      </SuspenseWithLoader>
    ),
  },
  {
    name: "Sign Up",
    url: "/sign-up",
    component: (
      <SuspenseWithLoader>
        <SignUp />
      </SuspenseWithLoader>
    ),
  },
];
