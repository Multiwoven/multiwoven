import { defineStyle, defineStyleConfig } from '@chakra-ui/styled-system'

const baseStyle = defineStyle({
  fontWeight: 'semibold',
})

const sizes = {
  '2xl': {
    fontSize: '7xl',
    lineHeight: '5.625rem',
    letterSpacing: 'tight',
  },
  xl: {
    fontSize: '6xl',
    lineHeight: '4.5rem',
    letterSpacing: 'tight',
  },
  lg: {
    fontSize: '5xl',
    lineHeight: '3.75rem',
    letterSpacing: 'tight',
  },
  md: {
    fontSize: '4xl',
    lineHeight: '2.75rem',
    letterSpacing: 'tight',
  },
  sm: {
    fontSize: '3xl',
    lineHeight: '2.375rem',
  },
  xs: {
    fontSize: '2xl',
    lineHeight: '2rem',
  },
}

export const headingTheme = defineStyleConfig({
  baseStyle,
  sizes,
})
