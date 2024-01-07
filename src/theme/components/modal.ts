import { modalAnatomy as parts } from '@chakra-ui/anatomy'
import { createMultiStyleConfigHelpers } from '@chakra-ui/styled-system'

const { defineMultiStyleConfig, definePartsStyle } = createMultiStyleConfigHelpers(parts.keys)

const baseStyle = definePartsStyle({
  overlay: {
    bg: 'bg.surface',
    p: 1,
    py: 2,
  },
  dialog: {
    color: 'fg.default',
    _focus: {
      boxShadow:
        '0px 0px 1px rgba(48, 49, 51, 0.05), 0px 8px 16px rgba(48, 49, 51, 0.1) !important',
    },
  },
  dialogContainer: {
    color: 'fg.default',
  },
  header: {
    pb: 0,
    lineHeight: '8',
    fontWeight: 'bold',
    fontSize: 'xl',
  },
  body: {
    color: 'subtle',
    fontSize: 'sm',
    lineHeight: '1.5',
    pt: 2,
    pb: 0,
  },
  footer: {
    py: 6,
  },
  closeButton: {
    color: 'accent',
  },
})

export const modalTheme = defineMultiStyleConfig({
  baseStyle,
})
