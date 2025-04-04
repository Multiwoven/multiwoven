import '@fontsource-variable/manrope';

export const defaultExtension = {
  colors: {
    mw_orange: '#E63D2D',
    brand: {
      100: '#CED3E0',
      200: '#A1ADD1',
      300: '#3652AE',
      400: '#00249C',
      500: '#001D7D',
      600: '#001560',
    },
    gray: {
      100: '#FFFFFF',
      200: '#F9FAFB',
      300: '#F2F4F7',
      400: '#EAECF0',
      500: '#D0D5DD',
      600: '#98A2B3',
    },
    black: {
      100: '#667085',
      200: '#475467',
      300: '#344054',
      400: '#1D2939',
      500: '#10182B',
      600: '#000000',
    },
    success: {
      100: '#DCF2EF',
      200: '#B7EDE3',
      300: '#71D9C6',
      400: '#33C0A7',
      500: '#129981',
      600: '#075042',
    },
    warning: {
      100: '#FFE6D4',
      200: '#FFD4B6',
      300: '#FFAF75',
      400: '#FF8F3E',
      500: '#F56412',
      600: '#932C00',
    },
    error: {
      100: '#FFEBEB',
      200: '#FAC5C5',
      300: '#F58E8E',
      400: '#F45757',
      500: '#C82727',
      600: '#761414',
    },
    info: {
      100: '#E0ECFF',
      200: '#BAD6FF',
      300: '#75ACFF',
      400: '#3E8BFF',
      500: '#0E54BD',
      600: '#032C6B',
    },
  },
  components: {
    Button: {
      variants: {
        solid: {
          bgColor: 'brand.400',
          _hover: { bgColor: 'brand.300' },
          color: 'white',
          _loading: {
            _hover: {
              bgColor: 'brand.400',
            },
          },
          _disabled: {
            _hover: {
              bgColor: 'brand.400',
            },
          },
        },
        outline: {
          bgColor: 'gray.100',
          _hover: { bgColor: 'brand.400', color: 'white' },
          color: 'brand.400',
          outline: '1px',
          borderColor: 'brand.400',
          _loading: {
            _hover: { bgColor: 'brand.400', color: 'white' },
          },
          _disabled: {
            _hover: { bgColor: 'brand.400', color: 'white' },
          },
        },
        ghost: {
          bgColor: 'gray.400',
          _hover: { bgColor: 'gray.500', color: 'black' },
          color: 'black',
          _loading: {
            _hover: { bgColor: 'gray.500', color: 'black' },
          },
          _disabled: {
            _hover: { bgColor: 'gray.500', color: 'black' },
          },
        },
        shell: {
          bgColor: 'gray.100',
          _hover: { bgColor: 'gray.300', color: 'black' },
          color: 'black',
          borderColor: 'gray.500',
          borderWidth: '1px',
          borderStyle: 'solid',
          _loading: {
            _hover: { bgColor: 'gray.300', color: 'black' },
          },
          _disabled: {
            _hover: { bgColor: 'gray.300', color: 'black' },
          },
        },
      },
      sizes: {
        xs: {
          h: '24px',
          w: '92px',
          px: '8px',
          gap: '6px',
          radius: '6px',
          fontSize: '14px',
          lineHeight: '20px',
          fontWeight: '700',
        },
        sm: {
          h: '32px',
          w: '114px',
          px: '12px',
          gap: '8px',
          radius: '6px',
          fontSize: '14px',
          lineHeight: '20px',
          fontWeight: '700',
        },
        md: {
          h: '40px',
          w: '126px',
          px: '16px',
          gap: '2px',
          radius: '8px',
          fontSize: '14px',
          lineHeight: '20px',
          fontWeight: '700',
        },
        lg: {
          h: '48px',
          w: '157px',
          px: '24px',
          gap: '2px',
          radius: '8px',
          fontSize: '14px',
          lineHeight: '20px',
          fontWeight: '700',
        },
      },
      loading: {
        _hover: {
          bgColor: 'green.200',
        },
      },
    },
    Text: {
      sizes: {
        xl: {
          fontSize: '20px',
          lineHeight: '30px',
        },
        lg: {
          fontSize: '18px',
          lineHeight: '28px',
        },
        md: {
          fontSize: '16px',
          lineHeight: '24px',
          letterSpacing: '-0.16px',
        },
        sm: {
          fontSize: '14px',
          lineHeight: '20px',
          letterSpacing: '-0.14px',
        },
        xs: {
          fontSize: '12px',
          lineHeight: '18px',
        },
        xxs: {
          fontSize: '10px',
          lineHeight: '16px',
        },
      },
      font: 'Manrope',
      weights: {
        regular: 400,
        medium: 500,
        semibold: 600,
        bold: 700,
        extrabold: 800,
      },
    },
    Heading: {
      sizes: {
        xl: {
          fontSize: '60px',
          lineHeight: '72px',
        },
        lg: {
          fontSize: '48px',
          lineHeight: '60px',
        },
        md: {
          fontSize: '36px',
          lineHeight: '44px',
        },
        sm: {
          fontSize: '30px',
          lineHeight: '38px',
        },
        xs: {
          fontSize: '24px',
          lineHeight: '32px',
        },
      },
      weight: {
        800: 'extrabold',
        700: 'bold',
        600: 'semibold',
        500: 'medium',
        400: 'regular',
      },
    },
    Input: {
      variants: {
        outline: {
          field: {
            bg: 'white',
            width: '100%',
            height: '40px',
            border: '1px',
            borderColor: 'gray.400',
            boxSizing: 'border-box',
            borderRadius: 8,
          },
        },
      },
    },
    Select: {
      variants: {
        outline: {
          field: {
            bgColor: 'gray.100',
            width: '100%',
            height: '32px',
            border: '1px',
            borderColor: 'gray.400',
            borderRadius: '6px',
            _disabled: {
              bgColor: 'gray.300',
              _hover: { bgColor: 'gray.300', color: 'black', cursor: 'not-allowed' },
            },
            _hover: { cursor: 'pointer' },
          },
        },
      },
    },
  },

  fonts: {
    heading: 'Manrope, sans-serif',
    body: 'Manrope, sans-serif',
  },
  fontSizes: {
    b3: '1rem',
    b4: '0.875rem',
    b5: '0.75rem',
  },
  lineHeights: {
    b3: '1.5rem',
    b4: '1.25rem',
    b5: '1.125rem',
  },
  letterSpacings: {
    b3: '-0.16px',
    b4: '-0.12px',
  },
  fontWeights: {
    semiBold: 600,
  },
  brandName: 'audiencesync',
  logoUrl: '',
  termsOfServiceUrl: 'https://multiwoven.com/terms-of-service',
  privacyPolicyUrl: 'https://multiwoven.com/privacy-policy',
};
