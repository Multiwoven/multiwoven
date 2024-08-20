import { Suspense, lazy } from 'react';
const AboutUs = lazy(() => import('@/views/AboutUs'));
const Dashboard = lazy(() => import('@/views/Dashboard'));
<<<<<<< HEAD
const SignIn = lazy(() => import('@/views/Authentication/SignIn'));
const SignUp = lazy(() => import('@/views/Authentication/SignUp'));
const Models = lazy(() => import('@/views/Models'));
=======

const SignIn = lazy(() => import('@/enterprise/views/Authentication/SignIn'));
const SignUp = lazy(() => import('@/enterprise/views/Authentication/SignUp'));

const SignUpVerification = lazy(
  () => import('@/enterprise/views/Authentication/SignUp/SignUpVerification'),
);
const VerifyUser = lazy(() => import('@/enterprise/views/Authentication/VerifyUser'));

const ForgotPassword = lazy(() => import('@/enterprise/views/Authentication/ForgotPassword'));
const ResetPassword = lazy(() => import('@/enterprise/views/Authentication/ResetPassword'));

const SetupDefine = lazy(() => import('@/views/Define/SetupDefine'));
>>>>>>> 5038b91c (refactor(CE): changed setup models to setup define)
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
<<<<<<< HEAD
        <Models />
=======
        <RoleAccess location='model' type='page' action={UserActions.Read}>
          <SetupDefine />
        </RoleAccess>
>>>>>>> 5038b91c (refactor(CE): changed setup models to setup define)
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
];
