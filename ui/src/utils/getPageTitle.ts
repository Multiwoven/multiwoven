import mwTheme from '@/chakra.config';

const ROUTE_MAP = {
  '/settings': 'Settings',
  '/activate/syncs': 'Syncs',
  '/setup/sources': 'Sources',
  '/define/models': 'Models',
  '/setup/destinations': 'Destinations',
};

const BRAND_NAME = mwTheme.brandName;

const getTitle = (pathname: string) => {
  if (pathname === '/') {
    return 'Dashboard | ' + BRAND_NAME;
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
