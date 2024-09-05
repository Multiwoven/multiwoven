import { Suspense, lazy } from 'react';
const AboutUs = lazy(() => import('@/views/AboutUs'));
const Dashboard = lazy(() => import('@/views/Dashboard'));
const SignIn = lazy(() => import('@/views/Authentication/SignIn'));
const SignUp = lazy(() => import('@/views/Authentication/SignUp'));

const SignUpVerification = lazy(() => import('@/views/Authentication/SignUp/SignUpVerification'));
const VerifyUser = lazy(() => import('@/views/Authentication/VerifyUser'));

const ForgotPassword = lazy(() => import('@/views/Authentication/ForgotPassword'));
const ResetPassword = lazy(() => import('@/views/Authentication/ResetPassword'));

const Models = lazy(() => import('@/views/Models'));
const SetupConnectors = lazy(() => import('@/views/Connectors/SetupConnectors'));

const SetupActivate = lazy(() => import('@/views/Activate/SetupActivate'));
const Settings = lazy(() => import('@/views/Settings'));

type MAIN_PAGE_ROUTES_ITEM = {
  name: string;
  url: string;
  component: JSX.Element;
};

interface SuspenseWithLoaderProps {
  children: React.ReactElement;
  redirectRoute: string;
}

const SuspenseWithLoader = ({ children }: SuspenseWithLoaderProps): JSX.Element => {
  return <Suspense>{children}</Suspense>;
};

export default SuspenseWithLoader;

export const MAIN_PAGE_ROUTES: MAIN_PAGE_ROUTES_ITEM[] = [
  {
    name: 'Homepage',
    url: '/',
    component: <SuspenseWithLoader redirectRoute='/'>{<Dashboard />}</SuspenseWithLoader>,
  },
  {
    name: 'About Us',
    url: '/about-us',
    component: (
      <SuspenseWithLoader redirectRoute='/about-us'>
        <AboutUs />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Define',
    url: '/define/*',
    component: (
      <SuspenseWithLoader redirectRoute='/define'>
        <Models />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Setup',
    url: '/setup/*',
    component: (
      <SuspenseWithLoader redirectRoute='/setup'>
        <SetupConnectors />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Syncs',
    url: '/activate/*',
    component: (
      <SuspenseWithLoader redirectRoute='/activate'>
        <SetupActivate />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Settings',
    url: '/settings/*',
    component: (
      <SuspenseWithLoader redirectRoute='/settings'>
        <Settings />
      </SuspenseWithLoader>
    ),
  },
];

export const AUTH_ROUTES: MAIN_PAGE_ROUTES_ITEM[] = [
  {
    name: 'Sign In',
    url: '/sign-in',
    component: (
      <SuspenseWithLoader redirectRoute='/sign-in'>
        <>
          <SignIn />
        </>
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Sign Up',
    url: '/sign-up',
    component: (
      <SuspenseWithLoader redirectRoute='/sign-up'>
        <>
          <SignUp />
        </>
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Sign Up Success',
    url: '/sign-up/success',
    component: (
      <SuspenseWithLoader redirectRoute='/sign-up'>
        <SignUpVerification />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Verify User',
    url: '/verify-user',
    component: (
      <SuspenseWithLoader redirectRoute='/verify-user'>
        <VerifyUser />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Forgot Password',
    url: '/forgot-password',
    component: (
      <SuspenseWithLoader redirectRoute='/forgot-password'>
        <ForgotPassword />
      </SuspenseWithLoader>
    ),
  },
  {
    name: 'Reset Password',
    url: '/reset-password',
    component: (
      <SuspenseWithLoader redirectRoute='/forgot-password'>
        <ResetPassword />
      </SuspenseWithLoader>
    ),
  },
];
