import { defaultExtension } from '@/chakra-core.config';

export const enterpriseExtension = () => {
  const extension = { ...defaultExtension };

  const env = {
    VITE_LOGO_URL:
      window?.VITE_LOGO_URL !== '__VITE_LOGO_URL__' && window?.VITE_LOGO_URL !== 'undefined'
        ? window?.VITE_LOGO_URL
        : import.meta.env.VITE_LOGO_URL || undefined,
    VITE_BRAND_NAME:
      window?.VITE_BRAND_NAME !== '__VITE_BRAND_NAME__' && window?.VITE_BRAND_NAME !== 'undefined'
        ? window?.VITE_BRAND_NAME
        : import.meta.env.VITE_BRAND_NAME || undefined,
    VITE_BRAND_COLOR:
      window?.VITE_BRAND_COLOR !== '__VITE_BRAND_COLOR__' &&
      window?.VITE_BRAND_COLOR !== 'undefined'
        ? window?.VITE_BRAND_COLOR
        : import.meta.env.VITE_BRAND_COLOR || undefined,
    VITE_BRAND_HOVER_COLOR:
      window?.VITE_BRAND_HOVER_COLOR !== '__VITE_BRAND_HOVER_COLOR__' &&
      window?.VITE_BRAND_HOVER_COLOR !== 'undefined'
        ? window?.VITE_BRAND_HOVER_COLOR
        : import.meta.env.VITE_BRAND_HOVER_COLOR || undefined,
    VITE_FAV_ICON_URL:
      window?.VITE_FAV_ICON_URL !== '__VITE_FAV_ICON_URL__' &&
      window?.VITE_FAV_ICON_URL !== 'undefined'
        ? window?.VITE_FAV_ICON_URL
        : import.meta.env.VITE_FAV_ICON_URL || undefined,
  };

  // Update the logo URL if environment variable exists
  if (env.VITE_LOGO_URL) {
    extension.logoUrl = env.VITE_LOGO_URL;
  }

  // Update the brand name if environment variable exists
  if (env.VITE_BRAND_NAME) {
    extension.brandName = env.VITE_BRAND_NAME;
  }

  // Update the fav icon if environment variable exists
  if (env.VITE_FAV_ICON_URL) {
    extension.favIconUrl = env.VITE_FAV_ICON_URL;
  }

  // Update the brand color if environment variable exists
  if (env.VITE_BRAND_COLOR) {
    extension.colors.brand[400] = env.VITE_BRAND_COLOR;
    extension.colors.brand[300] = env.VITE_BRAND_HOVER_COLOR;
  }

  return extension;
};
