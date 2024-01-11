import { progressAnatomy as parts } from '@chakra-ui/anatomy'

import { createMultiStyleConfigHelpers, defineStyle } from '@chakra-ui/styled-system'
import { generateStripe, getColor, mode, StyleFunctionProps } from '@chakra-ui/theme-tools'
import { getColorDefault } from '../foundations/tokens'

const { defineMultiStyleConfig, definePartsStyle } = createMultiStyleConfigHelpers(parts.keys)

const filledStyle = defineStyle((props: StyleFunctionProps & { onAccent?: boolean }) => {
  const { theme, isIndeterminate, hasStripe, onAccent } = props

  const stripeStyle = mode(generateStripe(), generateStripe('1rem', 'rgba(0,0,0,0.1)'))(props)

  const background = onAccent ? 'fg.accent.emphasis' : getColorDefault(props)

  const gradient = `linear-gradient(
    to right,
    transparent 0%,
    ${getColor(theme, background)} 50%,
    transparent 100%
  )`

  const addStripe = !isIndeterminate && hasStripe

  return {
    ...(addStripe && stripeStyle),
    ...(isIndeterminate ? { bgImage: gradient } : { background }),
  }
})

const variantSolid = definePartsStyle((props) => ({
  filledTrack: {
    transition: 'all 0.3s',
    ...filledStyle(props),
  },
  track: {
    background: 'bg.muted',
    borderRadius: props.borderRadius ?? 'full',
  },
}))

const variantOnAccent = definePartsStyle((props) => ({
  filledTrack: {
    ...filledStyle({ ...props, onAccent: true }),
  },
  track: {
    bg: 'bg.muted',
  },
}))

const variants = {
  solid: variantSolid,
  'fg.accent.default': variantOnAccent,
}

const defaultProps = {
  size: 'lg',
  variant: 'solid',
} as const

export const progressTheme = defineMultiStyleConfig({
  variants,
  defaultProps,
})
