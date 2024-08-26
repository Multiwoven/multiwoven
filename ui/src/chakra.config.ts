import { extendTheme } from '@chakra-ui/react';

import { defaultExtension } from './chakra-core.config';
import { switchAnatomy } from '@chakra-ui/anatomy';
import { createMultiStyleConfigHelpers } from '@chakra-ui/react';

const { definePartsStyle, defineMultiStyleConfig } = createMultiStyleConfigHelpers(
  switchAnatomy.keys,
);

const baseStyle = definePartsStyle({
  thumb: {
    bg: 'gray.100',
    borderRadius: '3px',
  },
  track: {
    bg: 'gray.500',
    borderRadius: '5px',
    _checked: {
      bg: 'brand.400',
    },
  },
});

export const switchTheme = defineMultiStyleConfig({ baseStyle });

const mwTheme = extendTheme(defaultExtension, { components: { Switch: switchTheme } });

export default mwTheme;
