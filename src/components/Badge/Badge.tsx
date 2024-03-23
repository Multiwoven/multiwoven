import { Box, Text } from '@chakra-ui/react';

type BadgeProps = {
  text: string;
  variant: 'success' | 'warning' | 'error' | 'info' | 'default';
  width?: string;
};

const colors = {
  default: {
    textColor: 'black.300',
    bgColor: 'gray.200',
    borderColor: 'gray.500',
  },

  info: {
    textColor: 'info.600',
    bgColor: 'info.100',
    borderColor: 'info.300',
  },
  error: {
    textColor: 'error.600',
    bgColor: 'error.100',
    borderColor: 'error.300',
  },
  warning: {
    textColor: 'warning.600',
    bgColor: 'warning.100',
    borderColor: 'warning.300',
  },
  success: {
    textColor: 'success.600',
    bgColor: 'success.100',
    borderColor: 'success.300',
  },
};

const Badge = ({ text, variant, width = '71px' }: BadgeProps): JSX.Element => {
  return (
    <Box
      w={width}
      h='20px'
      alignItems='center'
      alignContent='center'
      bgColor={variant ? colors[variant].bgColor : colors.default.bgColor}
      border='1px'
      borderRadius='4px'
      borderColor={variant ? colors[variant].borderColor : colors.default.borderColor}
      gap='10px'
      px='2px'
      display='flex'
    >
      <Text
        size='xxs'
        fontWeight='semibold'
        color={variant ? colors[variant].textColor : colors.default.textColor}
      >
        {text}
      </Text>
    </Box>
  );
};

export default Badge;
