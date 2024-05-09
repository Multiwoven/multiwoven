import { Box, HStack, Text } from '@chakra-ui/layout';
import { Link } from 'react-router-dom';
import mwTheme from '@/chakra.config';

const AuthFooter = (): JSX.Element => {
  const { brandName } = mwTheme;

  return (
    <Box
      backgroundColor='gray.100'
      display='flex'
      justifyContent='center'
      height='10vh'
      zIndex='1'
      width='full'
      alignItems='center'
    >
      <HStack spacing={1} justify='center'>
        <Text color='black.100' fontWeight='medium' size='xs'>
          {`© ${brandName} Inc. All rights reserved.`}
        </Text>
        <Link to='https://squared.ai/terms-of-service/' target='_blank'>
          <Text color='black.500' size='xs' fontWeight='semibold'>
            Terms of use
          </Text>
        </Link>
        <Text size='xs' color='black.100'>
          •
        </Text>
        <Link to='https://squared.ai/privacy-policy/' target='_blank'>
          <Text color='black.500' size='xs' fontWeight='semibold'>
            Privacy Policy
          </Text>
        </Link>
      </HStack>
    </Box>
  );
};

export default AuthFooter;
