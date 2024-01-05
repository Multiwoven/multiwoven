import { Suspense, lazy, useEffect } from "react";
import { useNavigate } from 'react-router-dom';
const AboutUs = lazy(() => import("@/views/AboutUs"));
const Dashboard = lazy(() => import("@/views/Dashboard"));
const Homepage = lazy(() => import("@/views/Homepage"));
const Login = lazy(() => import("@/views/Login"));
const SignUp = lazy(() => import("@/views/SignUp"));
const AccountVerify = lazy(() => import("@/views/AccountVerify"));
const Models = lazy(() => import("@/views/Models"));

import Cookies from 'js-cookie';

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
  redirectRoute,
}: SuspenseWithLoaderProps): JSX.Element => {
  const history = useNavigate();

  useEffect(() => {
    const token = Cookies.get('authToken');
    console.log("routename", redirectRoute)
    if (token) {
      history(redirectRoute);
      if (token && redirectRoute == '/sign-up') {
        history('/');
      } else if (token && redirectRoute == '/login') {
        history('/');
      } else if (token && redirectRoute == '/account-verify') {
        history('/');
      } else {
        history(redirectRoute);
      }
    } else if (redirectRoute == '/sign-up') {
      history(redirectRoute);
    } else if (redirectRoute == '/account-verify') {
      history(redirectRoute);
    } else {
      history('/login');
    }
  }, [redirectRoute, history]);

  return <Suspense>{children}</Suspense>;
};

export default SuspenseWithLoader;

export const MAIN_PAGE_ROUTES: MAIN_PAGE_ROUTES_ITEM[] = [
  {
    name: 'Homepage',
    url: '/',
    component: (
      <SuspenseWithLoader redirectRoute="/">
        <Homepage />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Dashboard',
    url: '/dashboard',
    component: (
      <SuspenseWithLoader redirectRoute="/dashboard">
        <Dashboard />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'About Us',
    url: '/about-us',
    component: (
      <SuspenseWithLoader redirectRoute="/about-us">
        <AboutUs />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Sources',
    url: '/sources',
    component: (
      <SuspenseWithLoader redirectRoute="/sources">
        <AboutUs />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Models',
    url: '/models',
    component: (
      <SuspenseWithLoader redirectRoute="/models">
        <Models />
      </SuspenseWithLoader>
    ),
  },
];

export const AUTH_ROUTES: MAIN_PAGE_ROUTES_ITEM[] = [
  {
    name: 'Login',
    url: '/login',
    component: (
      <SuspenseWithLoader redirectRoute="/login">
        <Login />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Sign Up',
    url: '/sign-up',
    component: (
      <SuspenseWithLoader redirectRoute="/sign-up">
        <SignUp />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Account Verify',
    url: '/account-verify',
    component: (
      <SuspenseWithLoader redirectRoute="/account-verify">
        <AccountVerify />
      </SuspenseWithLoader>
    ),
  },
];

