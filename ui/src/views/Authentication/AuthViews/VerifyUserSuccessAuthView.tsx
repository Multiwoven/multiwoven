import { useNavigate } from 'react-router-dom';
import AuthCard from '../AuthCard';
import { Button, Heading, Stack, Text } from '@chakra-ui/react';
import { VerifyUserSuccessAuthViewProps } from '../types';

export const VerifyUserSuccessAuthView = ({
  brandName,
  logoUrl,
}: VerifyUserSuccessAuthViewProps) => {
  const navigate = useNavigate();

  return (
    <>
      <AuthCard logoUrl={logoUrl} brandName={brandName}>
        <Stack spacing='8px' textAlign='center' mb='32px'>
          <Heading size='xs' fontWeight='semibold'>
            Email verified!
          </Heading>
          <Text size='sm' color='black.200'>
            Your account has been successfully verified.
          </Text>
        </Stack>
        <Stack spacing='6'>
          <Button
            type='submit'
            loadingText='Submitting'
            variant='shell'
            width='full'
            onClick={() => navigate('/sign-in')}
          >
            Back to {brandName}
          </Button>
        </Stack>
      </AuthCard>
    </>
  );
};
