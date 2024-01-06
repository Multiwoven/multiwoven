import { sliderAnatomy as parts } from '@chakra-ui/anatomy'
import { createMultiStyleConfigHelpers } from '@chakra-ui/styled-system'

const { defineMultiStyleConfig, definePartsStyle } = createMultiStyleConfigHelpers(parts.keys)

const baseStyle = definePartsStyle({
  container: {},
  track: {
    bg: 'bg.subtle',
  },
  filledTrack: {
    bg: 'accent',
  },
  thumb: {
    bg: 'accent',
    boxShadow: 'none',
    _focus: {
      boxShadow: 'none',
    },
  },
})

export const sliderTheme = defineMultiStyleConfig({
  baseStyle,
})
