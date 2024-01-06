import { selectAnatomy as parts } from '@chakra-ui/anatomy'
import { createMultiStyleConfigHelpers } from '@chakra-ui/styled-system'
import { mode, transparentize } from '@chakra-ui/theme-tools'
import { inputTheme } from './input'
const { defineMultiStyleConfig, definePartsStyle } = createMultiStyleConfigHelpers(parts.keys)

const variantOutline = definePartsStyle((props) => {
  const { theme } = props
  const inputOutlineStyle = inputTheme.variants?.outline.field

  return {
    field: {
      ...inputOutlineStyle,
      _active: {
        ...inputOutlineStyle?._focus,
        background: mode(
          transparentize('gray.500', 0.3)(theme),
          transparentize('gray.300', 0.3)(theme),
        )(props),
      },
      _disabled: {
        _hover: {},
        _active: {
          borderColor: 'border.disabled',
          bg: 'unset',
        },
      },
    },
    icon: {
      color: 'input-placeholder',
      '>svg': {
        fontSize: '1.5rem',
      },
    },
  }
})

const variants = {
  outline: variantOutline,
}

export const selectTheme = defineMultiStyleConfig({
  variants,
})
