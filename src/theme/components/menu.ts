import { menuAnatomy as parts } from '@chakra-ui/anatomy'

import { createMultiStyleConfigHelpers, defineStyle } from '@chakra-ui/styled-system'
import { mode } from '@chakra-ui/theme-tools'
import { runIfFn } from '@chakra-ui/utils'

const { defineMultiStyleConfig, definePartsStyle } = createMultiStyleConfigHelpers(parts.keys)

const baseStyleList = defineStyle((props) => ({
  bg: 'bg.surface',
  overflow: 'hidden',
  boxShadow: mode('md', 'md-dark')(props),
  color: 'fg.default',
  minW: '3xs',
  py: 'unset',
  zIndex: 1,
  borderRadius: 'md',
  borderWidth: '0',
}))

const baseStyleItem = defineStyle((props) => {
  return {
    py: 2,
    px: 4,
    bg: 'bg.surface',
    _focus: {
      bg: 'accent',
      color: 'fg.accent.default',
    },
    _active: {
      bg: 'accent',
      color: 'fg.accent.default',
      _disabled: {
        color: 'fg.default',
        bg: 'initial',
        cursor: 'not-allowed',
      },
    },
    _expanded: {
      bg: mode('gray.100', 'whiteAlpha.100')(props),
    },
    _disabled: {
      opacity: 1,
      color: 'disabled',
      cursor: 'not-allowed',
      _active: {
        color: 'disabled',
      },
    },
  }
})

const baseStyleGroupTitle = defineStyle({
  mx: 4,
  my: 2,
  fontWeight: 'semibold',
  fontSize: 'sm',
})

const baseStyleCommand = defineStyle({
  color: 'muted',
})

const baseStyleDivider = defineStyle({
  border: 0,
  borderBottom: '1px solid',
  borderBottomColor: 'bg.muted',
  my: 0,
  opacity: 0.6,
})

const baseStyle = definePartsStyle((props) => ({
  list: runIfFn(baseStyleList, props),
  item: runIfFn(baseStyleItem, props),
  groupTitle: baseStyleGroupTitle,
  command: baseStyleCommand,
  divider: baseStyleDivider,
}))

export const menuTheme = defineMultiStyleConfig({
  baseStyle,
})
