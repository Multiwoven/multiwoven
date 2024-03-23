import { Box, Center, Flex, Spinner } from '@chakra-ui/react';

const Loader = (): JSX.Element => {
  return (
    <Flex width='100%' height='100vh' alignContent='center' justifyContent='center'>
      <Center>
        <Box>
          <Spinner speed='0.8s' emptyColor='gray.200' color='brand.300' size='lg' />
        </Box>
      </Center>
    </Flex>
  );
};

export default Loader;
