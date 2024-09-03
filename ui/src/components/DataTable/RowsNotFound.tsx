import EmptyState from '@/assets/images/empty-state-illustration.svg';
import { Box, Image, Text } from '@chakra-ui/react';

const RowsNotFound = () => (
  <Box display='flex' w='fit-content' mx='auto' flexDirection='column' gap='20px' mt='20%'>
    <Image src={EmptyState} alt='empty-table' w='175px' h='132px' />
    <Text fontSize='xl' mx='auto' color='gray.600' fontWeight='semibold'>
      No rows found
    </Text>
  </Box>
);

export default RowsNotFound;
