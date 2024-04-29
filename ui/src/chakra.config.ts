import { extendTheme } from '@chakra-ui/react';

import { defaultExtension } from './chakra-core.config';

// Function to extend the theme with environment variables
const extendThemeWithEnv = (env: Record<string, string>) => {
  let extension = { ...defaultExtension };

  // Update the logo URL if environment variable exists
  if (env.VITE_LOGO_URL) {
    extension = {
      ...extension,
      logoUrl: env.VITE_LOGO_URL,
    };
  }

  // Update the brand name if environment variable exists
  if (env.VITE_BRAND_NAME) {
    extension = {
      ...extension,
      brandName: env.VITE_BRAND_NAME,
    };
  }

  // Update the brand color if environment variable exists

  if (env.VITE_BRAND_COLOR) {
    extension = {
      ...extension,
      colors: {
        ...extension.colors,
        brand: {
          ...extension.colors.brand,
          400: env.VITE_BRAND_COLOR,
        },
      },
      components: {
        ...extension.components,
        Button: {
          ...extension.components.Button,
          variants: {
            ...extension.components.Button.variants,
            solid: {
              ...extension.components.Button.variants.solid,
              _hover: { bgColor: env.VITE_BRAND_HOVER_COLOR },
            },
          },
        },
      },
    };
  }

  return extension;
};

const extenstion = extendThemeWithEnv(import.meta.env);

const mwTheme = extendTheme(extenstion);

export default mwTheme;
