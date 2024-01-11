import { tableAnatomy as parts } from '@chakra-ui/anatomy'
import { createMultiStyleConfigHelpers } from '@chakra-ui/styled-system'

const { defineMultiStyleConfig, definePartsStyle } = createMultiStyleConfigHelpers(parts.keys)

const baseStyle = definePartsStyle({
  table: {
    fontVariantNumeric: 'lining-nums tabular-nums',
    borderCollapse: 'collapse',
    width: 'full',
  },

  caption: {
    color: 'fg.default',
    mt: 4,
    fontFamily: 'heading',
    textAlign: 'center',
    fontWeight: 'medium',
  },
})

const variantSimple = definePartsStyle({
  th: {
    bg: 'bg.subtle',
    color: 'fg.default',
    fontWeight: 'bold',
    fontSize: 'md',
    height: 14,
    border: 'unset',
  },
  td: {
    bg: 'bg.surface',
    color: 'fg.default',
    borderBottom: 'unset',
  },
})

const variantStripe = definePartsStyle({
  th: {
    bg: 'bg.subtle',
    color: 'fg.default',
    fontWeight: 'bold',
    fontSize: 'md',
    height: 14,
    border: 'unset',
  },
  td: {
    bg: 'bg.surface',
    color: 'fg.default',
    borderBottom: 'unset',
  },
  tbody: {
    td: {
      bg: 'unset',
    },
    tr: {
      '&:nth-of-type(odd)': {
        'th, td': {
          bg: 'white !important',
          _dark: {
            bg: 'gray.950 !important',
          },
        },
      },
      '&:nth-of-type(even)': {
        'th, td': {
          bg: 'bg.subtle',
          borderBottomWidth: 'unset',
        },
        td: {},
      },
    },
  },
})

const variants = {
  simple: variantSimple,
  striped: variantStripe,
}

export const tableTheme = defineMultiStyleConfig({
  baseStyle,
  variants,
})
