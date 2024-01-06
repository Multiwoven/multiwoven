import { defineStyle, defineStyleConfig } from '@chakra-ui/styled-system'

const baseStyle = defineStyle({
  flexShrink: 0,
  borderRadius: 'base',
  ':focus:not(:focus-visible)': {
    boxShadow: 'none',
  },
  fontWeight: 'bold',
  _focus: {
    boxShadow: 'none',
  },
})

const variantPrimary = defineStyle({
  color: 'fg.accent.default',
  bg: 'accent',
  _hover: {
    bg: 'accent-muted',
    _disabled: {
      background: 'fg.accent.disabled',
      color: 'on-disabled',
    },
  },
  _active: {
    bg: 'bg.accent.emphasis',
  },
  _disabled: {
    color: 'on-disabled',
    bg: 'fg.accent.disabled',
  },
})

const variantSecondary = defineStyle({
  bg: 'transparent',
  borderWidth: '2px',
  color: 'fg.muted',
  borderColor: 'bg.muted',
  '>svg *, >span>svg *': {
    filter: 'grayscale(100%)',
  },
  _hover: {
    color: 'fg.muted',
    bg: 'bg.subtle',
    borderColor: 'bg.muted',
    _disabled: {
      color: 'fg.disabled',
      borderColor: 'border.disabled',
    },
  },
  _active: {
    color: 'fg.muted',
    bg: 'bg.muted',
  },
  _disabled: {
    color: 'fg.disabled',
    borderColor: 'border.disabled',
  },
})

const variantTertiary = defineStyle({
  color: 'emphasized',
  bg: 'none',
  _hover: {
    bg: 'bg.subtle',
    _disabled: {
      color: 'fg.disabled',
    },
  },
  _active: {
    color: 'emphasized',
    bg: 'bg.muted',
  },
  _activeLink: {
    color: 'fg.accent.default',
    bg: 'accent',
    '*>svg': {
      color: 'fg.accent.default',
    },
  },
  _disabled: {
    color: 'fg.disabled',
  },
})

const variantText = defineStyle({
  padding: 0,
  textTransform: 'normal',
  fontWeight: 'normal',
  fontSize: 'md',
  _active: {
    _disabled: {
      opacity: '0.4',
    },
  },
})

const variants = {
  primary: variantPrimary,
  'primary.accent': defineStyle({
    bg: 'fg.accent.default',
    color: 'bg.accent.emphasis',
    _hover: {
      bg: 'fg.accent.muted',
      _disabled: {
        bg: 'fg.accent.default',
      },
    },
    _active: { bg: 'fg.accent.emphasis' },
  }),
  secondary: variantSecondary,
  'secondary.accent': {
    color: 'fg.accent.default',
    _hover: {
      color: 'fg.accent.muted',
      bg: 'bg.accent.muted',
    },
    _active: {
      color: 'bg.accent.emphasis',
      bg: 'bg.accent.emphasis',
    },
  },
  solid: variantPrimary,
  tertiary: variantTertiary,
  ghost: variantTertiary,
  text: variantText,
  link: variantText,
  // 'secondary.accent': defineStyle({
  //   border: '1px',
  //   borderColor: 'fg.accent.default',
  //   color: 'fg.accent.default',
  //   _hover: {
  //     color: 'fg.accent.muted',
  //     bg: 'bg.accent.muted',
  //   },
  //   _active: {
  //     color: 'fg.accent.emphasis',
  //     bg: 'bg.accent.emphasis',
  //   },
  // }),
  'tertiary.accent': defineStyle({
    color: 'fg.accent.default',
    bg: 'bg.accent.default',
    _hover: {
      color: 'fg.accent.subtle',
      bg: 'bg.accent.subtle',
    },
    _activeLink: {
      color: 'fg.accent.default',
      bg: 'bg.accent.muted',
    },
    _active: {
      bg: 'bg.accent.muted',
    },
  }),
}

const sizes = {
  '2xs': {
    h: 6,
    minW: 8,
    fontSize: '2xs',
    px: 4,
  },
  xs: {
    h: 8,
    minW: 8,
    fontSize: 'xs',
    px: 4,
  },
  sm: {
    h: 9,
    minW: 8,
    fontSize: 'sm',
    px: 4,
  },
  md: {
    h: 10,
    minW: 10,
    fontSize: 'md',
    px: 4,
  },
  lg: {
    h: 11,
    minW: 12,
    px: 4,
    fontSize: 'lg',
  },
  xl: {
    h: 12,
    minW: 16,
    px: 4,
    fontSize: 'xl',
  },
  '2xl': {
    h: 15,
    minW: 16,
    px: 4,
    fontSize: '2xl',
  },
}

export const buttonTheme = defineStyleConfig({ baseStyle, variants, sizes })
