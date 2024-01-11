import { radioAnatomy as parts } from '@chakra-ui/anatomy'
import { createMultiStyleConfigHelpers } from '@chakra-ui/styled-system'
import { checkboxTheme } from './checkbox'
const { defineMultiStyleConfig, definePartsStyle } = createMultiStyleConfigHelpers(parts.keys)

const baseStyle = definePartsStyle({
  control: {
    bg: 'unset',
    borderColor: 'accent',

    _hover: {
      bg: 'unset',
      borderColor: 'bg.accent.emphasis',
      _disabled: {
        borderColor: 'disabled',
      },
    },
    _checked: {
      bg: 'unset',
      color: 'accent',
      borderColor: 'accent',
      _hover: {
        bg: 'unset',
        color: 'bg.accent.emphasis',
        borderColor: 'bg.accent.emphasis',
      },
      _disabled: {
        bg: 'unset',
        color: 'disabled',
        borderColor: 'disabled',
        _hover: {
          borderColor: 'disabled',
        },
      },
    },
    _focus: {
      boxShadow: 'none',
    },
    _disabled: {
      bg: 'unset',
      cursor: 'not-allowed',
      borderColor: 'disabled',
      _hover: {
        borderColor: 'disabled',
      },
    },
    label: checkboxTheme.baseStyle?.label,
  },
})

const sizes = {
  md: {
    control: {
      width: 5,
      height: 5,
      _checked: {
        _before: {
          w: 2.5,
          h: 2.5,
        },
      },
    },
    label: { fontSize: 'sm' },
  },
  lg: {
    control: {
      width: 6,
      height: 6,
      _checked: {
        _before: {
          w: 3.5,
          h: 3.5,
        },
      },
    },
    Label: { fontSize: 'md' },
  },
}

export const radioTheme = defineMultiStyleConfig({
  baseStyle,
  sizes,
})
