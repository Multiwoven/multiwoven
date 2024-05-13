import { Box, Button, Center, Image, Text, VStack } from '@chakra-ui/react';
import NotFoundImage from '@/assets/images/404-image.png';
import { FiRefreshCw } from 'react-icons/fi';

const ServerError = (): JSX.Element => {
  return (
    <Box mx='auto' height='100vh' width='100%'>
      <Center h='100%'>
        <Box width='3xl' height='xl'>
          <VStack mx='auto' spacing={6}>
            <Image src={NotFoundImage} />
            <Text color='black' fontSize='2xl' textAlign='center' fontWeight='medium'>
              There was a connection error to the server. Please try again later.
            </Text>
            <Text color='black' fontSize='md' mt={-2} textAlign='center' fontWeight='medium'></Text>
            <Button size='lg' onClick={() => window.location.reload()} leftIcon={<FiRefreshCw />}>
              Retry
            </Button>
          </VStack>
        </Box>
      </Center>
    </Box>
  );
};

export default ServerError;
