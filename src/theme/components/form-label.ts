import { defineStyle, defineStyleConfig } from '@chakra-ui/styled-system'
import { checkboxTheme } from './checkbox'

const baseStyle = defineStyle({
  ...checkboxTheme.baseStyle?.label,
  lineHeight: 7,
  _disabled: {
    opacity: 1,
    color: 'disabled',
  },
})

const sizes = {
  sm: defineStyle({
    _peerPlaceholderShown: {
      fontSize: 'sm',
      top: '0.5',
      left: '4',
    },
  }),
  md: defineStyle({
    _peerPlaceholderShown: {
      fontSize: 'md',
      top: '1.5',
      left: '4',
    },
  }),
  lg: defineStyle({
    _peerPlaceholderShown: {
      fontSize: 'lg',
      top: '2.5',
      left: '4',
    },
  }),
}

export const formLabelTheme = defineStyleConfig({
  baseStyle,
  sizes,
})
