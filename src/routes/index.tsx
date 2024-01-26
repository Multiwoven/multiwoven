import { Suspense, lazy } from "react";
const AboutUs = lazy(() => import("@/views/AboutUs"));
const Dashboard = lazy(() => import("@/views/Dashboard"));
const Homepage = lazy(() => import("@/views/Homepage"));
const Login = lazy(() => import("@/views/Login"));
const SignUp = lazy(() => import("@/views/SignUp"));
const AccountVerify = lazy(() => import("@/views/AccountVerify"));
const Models = lazy(() => import("@/views/Models"));
const SetupConnectors = lazy(
  () => import("@/views/Connectors/SetupConnectors")
);
// const Sources = lazy(() => import("@/views/Connectors/Sources"));

import Cookies from "js-cookie";
// import { ConnectorModify } from "@/views/Connectors/ConnectorModify";

type MAIN_PAGE_ROUTES_ITEM = {
  name: string;
  url: string;
  component: JSX.Element;
};

interface SuspenseWithLoaderProps {
  children: React.ReactElement;
  redirectRoute: string;
}

const SuspenseWithLoader = ({
  children,
}: SuspenseWithLoaderProps): JSX.Element => {
  return <Suspense>{children}</Suspense>;
};

export default SuspenseWithLoader;

export const MAIN_PAGE_ROUTES: MAIN_PAGE_ROUTES_ITEM[] = [
  {
    name: "Homepage",
    url: "/",
    component: (
      <SuspenseWithLoader redirectRoute="/">
        <Homepage />
      </SuspenseWithLoader>
    ),
  },
  {
    name: "Dashboard",
    url: "/dashboard",
    component: (
      <SuspenseWithLoader redirectRoute="/dashboard">
        <Dashboard />
      </SuspenseWithLoader>
    ),
  },
  {
    name: "About Us",
    url: "/about-us",
    component: (
      <SuspenseWithLoader redirectRoute="/about-us">
        <AboutUs />
      </SuspenseWithLoader>
    ),
  },
  {
    name: "Models",
    url: "/models/*",
    component: (
      <SuspenseWithLoader redirectRoute="/models">
        <Models />
      </SuspenseWithLoader>
    ),
  },
  {
    name: "Setup",
    url: "/setup/*",
    component: (
      <SuspenseWithLoader redirectRoute="/setup">
        <SetupConnectors />
      </SuspenseWithLoader>
    ),
  },
];

export const AUTH_ROUTES: MAIN_PAGE_ROUTES_ITEM[] = [
  {
    name: "Login",
    url: "/login",
    component: (
      <SuspenseWithLoader redirectRoute="/login">
        <Login />
      </SuspenseWithLoader>
    ),
  },
  {
    name: "Sign Up",
    url: "/sign-up",
    component: (
      <SuspenseWithLoader redirectRoute="/sign-up">
        <SignUp />
      </SuspenseWithLoader>
    ),
  },
  {
    name: "Account Verify",
    url: "/account-verify",
    component: (
      <SuspenseWithLoader redirectRoute="/account-verify">
        <AccountVerify />
      </SuspenseWithLoader>
    ),
  },
];