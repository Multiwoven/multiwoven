import { tabsAnatomy as parts } from '@chakra-ui/anatomy'
import { createMultiStyleConfigHelpers } from '@chakra-ui/styled-system'
import { mode } from '@chakra-ui/theme-tools'

const { defineMultiStyleConfig, definePartsStyle } = createMultiStyleConfigHelpers(parts.keys)

const baseStyle = definePartsStyle((props) => ({
  root: {
    pos: 'relative',
  },
  tab: {
    flex: props.isFitted ? 1 : undefined,
    color: 'subtle',
    textTransform: 'uppercase',
    fontSize: 'sm',
    _selected: {
      color: 'accent',
    },
  },
}))

const getVariantLine = definePartsStyle((props) => {
  const { colorScheme } = props
  const borderProp = props.orientation === 'vertical' ? 'borderStart' : 'borderBottom'

  return {
    tablist: {
      borderBottom: 'unset',
      borderStart: 'unset',
    },
    tab: {
      _selected: {
        borderColor: 'accent',
        [borderProp + 'Width']: '2px',
      },
      _disabled: {
        color: 'disabled',
        cursor: 'not-allowed',
      },
    },
    indicator: {
      bg: mode(`${colorScheme}.500`, `${colorScheme}.400`)(props),
      mt: -1,
      height: 1,
      borderTopRadius: 'base',
      position: 'absolute',
    },
  }
})

const indicatorStyle = definePartsStyle(() => {
  return {
    tab: {
      _selected: {
        color: 'fg.accent.default',
      },
    },
    indicator: {
      boxShadow: 'none',
      bg: 'bg.accent.subtle',
      _dark: {
        bg: 'bg.accent.subtle', // overrides pro-theme's dark bg
      },
      color: 'fg.accent.default',
    },
  }
})

const variants = {
  line: getVariantLine,
  indicator: indicatorStyle,
}

const defaultProps = {
  variant: 'line',
  colorScheme: 'green',
} as const

export const tabsTheme = defineMultiStyleConfig({
  baseStyle,
  variants,
  defaultProps,
})
