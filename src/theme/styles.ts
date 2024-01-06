import { mode, Styles } from '@chakra-ui/theme-tools'

export const styles: Styles = {
  global: (props) => ({
    body: {
      fontFamily: 'body',
      color: 'fg.default',
      bg: 'bg.canvas',
    },
    '*::placeholder': {
      color: mode('gray.500', 'gray.500')(props),
    },
    '*, *::before, &::after': {
      borderColor: mode('gray.300', 'gray.300')(props),
    },
    'html,body': {
      height: '100%',
    },
    '#__next, #root': {
      display: 'flex',
      flexDirection: 'column',
      minH: '100%',
    },
  }),
}
