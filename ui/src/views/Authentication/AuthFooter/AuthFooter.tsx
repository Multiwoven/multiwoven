import { Box } from '@chakra-ui/layout';

type AuthFooterProps = {
  brandName: string;
  privacyPolicyUrl: string;
  termsOfServiceUrl: string;
};

const AuthFooter = (_props: AuthFooterProps): JSX.Element => {
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
    </Box>
  );
};

export default AuthFooter;
