import { Box, Container, Flex, Image, Stack } from '@chakra-ui/react';
import { AuthCardProps } from '../types';

const AuthCard = ({ children, brandName, logoUrl }: AuthCardProps): JSX.Element => (
  <>
    <Flex justify='center' w='100%' minHeight='90vh' alignItems='center' overflowY='auto'>
      <Container width={{ base: '400px', sm: '500px' }} py='6'>
        <Stack>
          <Box position='relative' top='12'>
            <Box
              bgColor={logoUrl ? 'gray.100' : 'brand.400'}
              h='80px'
              w={logoUrl ? '150px' : '80px'}
              display='flex'
              justifyContent='center'
              alignItems='center'
              borderRadius='11px'
              mx='auto'
            >
              <Image src={logoUrl} width={'100%'} alt={`${brandName} Logo in White`} />
            </Box>
          </Box>
          <Box
            padding='20px'
            borderRadius='10px'
            border='1px'
            borderColor='gray.400'
            paddingTop='60px'
          >
            {children}
          </Box>
        </Stack>
      </Container>
    </Flex>
  </>
);

export default AuthCard;
