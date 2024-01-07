import { defineStyle, defineStyleConfig } from '@chakra-ui/styled-system'

const baseStyle = defineStyle({
  _focus: {
    boxShadow: 'none',
  },
})

export const closeButtonTheme = defineStyleConfig({
  baseStyle,
})
