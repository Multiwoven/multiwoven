import { Box, Text } from '@chakra-ui/react';

export const TabBadge = ({ text }: { text: string }): JSX.Element => {
  return (
    <Box
      height='fit-content'
      bgColor='gray.300'
      borderWidth='1px'
      borderColor='gray.400'
      px='4px'
      borderRadius='100%'
    >
      <Text fontSize='xs' color='black.400'>
        {text}
      </Text>
    </Box>
  );
};
