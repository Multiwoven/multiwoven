import { defineStyle, defineStyleConfig } from '@chakra-ui/styled-system'
import { mode, transparentize } from '@chakra-ui/theme-tools'

const baseStyle = defineStyle({
  pl: 5,
  pr: 5,
  lineHeight: '1.25rem',
  fontSize: 'xs',
  fontWeight: 'bold',
  textTransform: 'uppercase',
})

const variantSolid = defineStyle(() => {
  return {
    bg: 'accent-muted',
    color: 'fg.accent.default',
  }
})

const variantSubtle = defineStyle((props) => {
  const { theme } = props

  return {
    color: 'accent',
    bg: mode(
      transparentize('brand.500', 0.1)(theme),
      transparentize('brand.400', 0.1)(theme),
    )(props),
  }
})

const variants = {
  solid: variantSolid,
  subtle: variantSubtle,
}

const defaultProps = {
  variant: 'solid',
} as const

export const badgeTheme = defineStyleConfig({
  baseStyle,
  variants,
  defaultProps,
})
