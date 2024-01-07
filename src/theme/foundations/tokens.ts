import { mode, StyleFunctionProps } from '@chakra-ui/theme-tools'
import shadows from './shadows'

export const getColorDefault = (props: StyleFunctionProps) =>
  mode(`${props.colorScheme}.500`, `${props.colorScheme}.400`)(props)

export const getBgMuted = (props: StyleFunctionProps) =>
  mode(`${props.colorScheme}.300`, `${props.colorScheme}.600`)(props)

export default {
  colors: {
    'bg.canvas': {
      default: 'gray.50',
      _dark: 'black',
    },
    'bg.surface': {
      default: 'white',
      _dark: 'gray.950',
    },
    'bg.subtle': {
      default: 'gray.200',
      _dark: 'gray.900',
    },
    'bg.muted': {
      default: 'gray.300',
      _dark: 'gray.600',
    },
    'fg.default': {
      default: 'black',
      _dark: 'white',
    },
    'fg.emphasized': {
      default: 'gray.800',
      _dark: 'gray.100',
    },
    'fg.muted': {
      default: 'gray.700',
      _dark: 'gray.200',
    },
    'fg.subtle': {
      default: 'gray.500',
      _dark: 'gray.500',
    },
    'fg.disabled': { default: 'gray.400', _dark: 'gray.600' },
    'on-disabled': { default: 'gray.600', _dark: 'gray.300' },
    'fg.accent.default': 'white',
    'fg.accent.muted': 'brand.100',
    'fg.accent.subtle': 'brand.50',
    'fg.accent.emphasis': 'white',
    accent: { default: 'brand.500', _dark: 'brand.400' },
    'bg.accent.default': 'brand.600',

    'accent-subtle': { default: 'brand.50', _dark: 'brand.950' },
    'bg.accent.subtle': 'brand.500',

    'accent-muted': { default: 'brand.400', _dark: 'brand.600' },
    'bg.accent.muted': 'brand.400',

    'bg.accent.emphasis': { default: 'brand.600', _dark: 'brand.500' },
    'fg.accent.disabled': { default: 'gray.300', _dark: 'gray.600' },
    'border.default': {
      default: 'gray.300',
      _dark: 'gray.600',
    },
    'border.emphasized': {
      default: 'gray.400',
      _dark: 'gray.500',
    },
    'border.disabled': { default: 'gray.300', _dark: 'gray.600' },
    'input-placeholder': 'gray.500',
  },
  shadows,
}
