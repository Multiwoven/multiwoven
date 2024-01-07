import { checkboxAnatomy as parts } from '@chakra-ui/anatomy'
import { createMultiStyleConfigHelpers } from '@chakra-ui/styled-system'

const { definePartsStyle, defineMultiStyleConfig } = createMultiStyleConfigHelpers(parts.keys)

const baseStyle = definePartsStyle({
  icon: {
    color: 'fg.accent.default',
  },
  control: {
    bg: 'unset',
    borderColor: 'bg.muted',
    '>div>svg': {
      color: 'accent',
      _hover: {
        color: 'bg.accent.emphasis',
      },
    },
    _hover: {
      bg: 'bg.subtle',
      borderColor: 'bg.muted',
      '>svg': {
        color: 'bg.accent.emphasis',
      },
    },
    _active: {
      bg: 'bg.muted',
    },
    _checked: {
      bg: 'unset',
      color: 'accent',
      borderColor: 'bg.muted',
      '>div>svg': {
        color: 'accent',
      },
      _hover: {
        bg: 'bg.subtle',
        color: 'bg.accent.emphasis',
        borderColor: 'bg.muted',
        '>div>svg': {
          color: 'bg.accent.emphasis',
        },
      },
      _active: {
        bg: 'bg.muted',
      },
      _disabled: {
        bg: 'unset',
        borderColor: 'disabled',
        _hover: {
          borderColor: 'disabled',
        },
        _active: {
          bg: 'unset',
        },
      },
    },
    _indeterminate: {
      borderColor: 'bg.muted',
      _hover: {
        borderColor: 'bg.muted',
      },
      bg: 'unset',
      '>div>svg': {
        color: 'accent',
        _hover: {
          color: 'bg.accent.emphasis',
        },
      },
      _disabled: {
        '>div>svg': {
          color: 'disabled',
        },
      },
    },
    _focus: {
      boxShadow: 'none',
    },
    _disabled: {
      bg: 'unset',
      borderColor: 'disabled',
      _hover: {
        borderColor: 'disabled',
      },
      _checked: {
        '>div>svg': {
          color: 'disabled',
        },
      },
      '>div>svg': {
        color: 'disabled',
      },
    },
  },
  label: {
    color: 'fg.default',
    _disabled: {
      opacity: 'unset',
      color: 'disabled',
    },
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

export const checkboxTheme = defineMultiStyleConfig({
  baseStyle,
  sizes,
})
