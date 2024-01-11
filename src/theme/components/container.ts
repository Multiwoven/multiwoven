import { defineStyle, defineStyleConfig } from '@chakra-ui/styled-system'

const baseStyle = defineStyle({
  maxW: '7xl',
  px: { base: '4', md: '8' },
})

export const containerTheme = defineStyleConfig({
  baseStyle,
})
