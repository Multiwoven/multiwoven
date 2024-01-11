import { inputAnatomy as parts } from '@chakra-ui/anatomy'
import { createMultiStyleConfigHelpers } from '@chakra-ui/styled-system'

const { definePartsStyle, defineMultiStyleConfig } = createMultiStyleConfigHelpers(parts.keys)

const variants = {
  outline: definePartsStyle({
    field: {
      color: 'emphasized',
      bg: 'inherit',
      borderRadius: 'base',
      border: '2px',
      borderColor: 'border.default',
      _hover: {
        bg: 'bg.subtle',
        borderColor: 'border.default',
      },
      _active: {
        _hover: {
          bg: 'unset',
        },
      },
      _focus: {
        boxShadow: 'unset',
        borderColor: 'bg.accent.emphasis',
        _hover: {
          bg: 'unset',
        },
      },
      _invalid: {
        boxShadow: 'unset',
        borderColor: 'red.500',
      },
      _placeholder: {
        opacity: 'unset',
        color: 'subtle',
        display: 'block',
      },
      _readOnly: {
        color: 'subtle',
      },
      _disabled: {
        borderColor: 'border.disabled',
        _placeholder: {
          color: 'disabled',
        },
      },
    },
    addon: {
      bg: 'blackAlpha.50',
      _dark: {
        bg: 'whiteAlpha.50',
        color: 'fg.subtle',
      },
      color: 'gray.800',
      border: '2px solid',
      borderColor: 'border.default',
      marginEnd: '-2px',
    },
  }),
  filled: definePartsStyle({
    field: {
      borderRadius: 'base',
      bg: 'bg.accent.muted',
      color: 'fg.accent.subtle',
      _hover: {
        bg: 'bg.accent.muted',
        borderColor: 'fg.accent.default',
      },
      _placeholder: {
        color: 'fg.accent.subtle',
      },
      _focus: {
        bg: 'bg.accent.muted',
        borderColor: 'fg.accent.default',
        color: 'fg.accent.default',
        _placeholder: {
          color: 'fg.accent.default',
        },
      },
    },
  }),
}

export const inputTheme = defineMultiStyleConfig({
  variants,
})
