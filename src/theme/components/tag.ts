import { tagAnatomy as parts } from '@chakra-ui/anatomy'
import { createMultiStyleConfigHelpers } from '@chakra-ui/styled-system'
import { getBgMuted, getColorDefault } from '../foundations/tokens'

const { defineMultiStyleConfig, definePartsStyle } = createMultiStyleConfigHelpers(parts.keys)

const baseStyle = definePartsStyle((props) => ({
  container: {
    background: 'bg.muted',
    color: props.colorScheme ? getColorDefault(props) : 'fg.default',
  },
  closeButton: {
    color: 'subtle',
  },
}))

const variantSubtle = definePartsStyle((props) => ({
  container: {
    borderRadius: 'base',
    color: props.colorScheme ? getColorDefault(props) : 'fg.default',
  },
  closeButton: {
    color: 'subtle',
  },
}))

const variantSolid = definePartsStyle({
  container: {
    borderRadius: 'base',
    bg: 'bg.muted',
    color: 'fg.default',
  },
  closeButton: {
    color: 'subtle',
  },
})

const variantOutline = definePartsStyle((props) => ({
  container: {
    borderRadius: 'base',
    borderColor: 'bg.muted',
    color: props.colorScheme ? getColorDefault(props) : 'fg.default',
    bg: 'unset',
  },
  closeButton: {
    color: 'subtle',
  },
}))

const variantChip = definePartsStyle((props) => ({
  container: {
    borderRadius: 'full',
    bg: props.colorScheme ? getBgMuted(props) : 'bg.muted',
    color: 'fg.default',
  },
  closeButton: {
    color: 'subtle',
  },
}))

const variants = {
  subtle: variantSubtle,
  solid: variantSolid,
  outline: variantOutline,
  chip: variantChip,
}

const defaultProps = {
  colorScheme: 'gray',
} as const

export const tagTheme = defineMultiStyleConfig({
  baseStyle,
  defaultProps,
  variants,
})
