import { Box, Button, Center, Image, Text, VStack } from '@chakra-ui/react';
import NotFoundImage from '@/assets/images/404-image.png';
import { FiArrowLeft } from 'react-icons/fi';
import { useNavigate } from 'react-router-dom';

const PageNotFound = (): JSX.Element => {
  const navigate = useNavigate();

  return (
    <Box mx='auto' height='100vh' width='100%'>
      <Center h='100%'>
        <Box width='3xl' height='xl'>
          <VStack mx='auto' spacing={6}>
            <Image src={NotFoundImage} />
            <Text color='black' fontSize='2xl' textAlign='center' fontWeight='medium'>
              The best open source data activation platform exists, but unfortunately, this page
              doesn’t.
            </Text>
            <Text color='black' fontSize='md' mt={-2} textAlign='center' fontWeight='medium'>
              We’d love to help you find what you are looking for. Please check the URL or go back.
            </Text>
            <Button size='lg' onClick={() => navigate(-1)}>
              <FiArrowLeft />
              Go Back
            </Button>
          </VStack>
        </Box>
      </Center>
    </Box>
  );
};

export default PageNotFound;
