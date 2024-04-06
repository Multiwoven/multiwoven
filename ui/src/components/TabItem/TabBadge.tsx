import { Box, Text } from '@chakra-ui/react';

export const TabBadge = ({
  text,
  isTabSelected,
}: {
  text: string;
  isTabSelected: boolean;
}): JSX.Element => {
  return (
    <Box
      height='fit-content'
      bgColor={isTabSelected ? 'gray.300' : 'gray.100'}
      borderWidth='1px'
      borderColor='gray.400'
      px='4px'
      borderRadius='100px'
    >
      <Text fontSize='xs' color='black.400'>
        {text}
      </Text>
    </Box>
  );
};
