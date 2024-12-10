import { BRAND_NAME } from '@/enterprise/app-constants';

const ROUTE_MAP = {
  '/reports': 'Reports',
  '/data-apps': 'Data Apps',
  '/settings': 'Settings',
  '/activate/syncs': 'Syncs',
  '/setup/sources': 'Sources',
  '/define/models': 'Models',
  '/setup/destinations': 'Destinations',
};

const getTitle = (pathname: string) => {
  if (pathname === '/') {
    return 'Reports | ' + BRAND_NAME;
  }
  const normalizedPath = pathname.replace(/\/+$/, '');
  const matchingRoute = Object.keys(ROUTE_MAP).find((route) => normalizedPath.startsWith(route));

  const title = matchingRoute ? ROUTE_MAP[matchingRoute as keyof typeof ROUTE_MAP] : null;

  if (title) {
    return title + ' | ' + BRAND_NAME;
  }
  return BRAND_NAME;
};

export default getTitle;
