import { useNavigate } from 'react-router-dom';
import AuthCard from '../AuthCard';
import { Button, Heading, Stack, Text } from '@chakra-ui/react';

type ResetPasswordSuccessAuthViewProps = {
  brandName: string;
  logoUrl: string;
  submitting: boolean;
};

export const ResetPasswordSuccessAuthView = ({
  brandName,
  logoUrl,
  submitting,
}: ResetPasswordSuccessAuthViewProps) => {
  const navigate = useNavigate();

  return (
    <>
      <AuthCard logoUrl={logoUrl} brandName={brandName}>
        <Stack spacing='8px' textAlign='center' mb='32px'>
          <Heading size='xs' fontWeight='semibold'>
            Password Changed!
          </Heading>
          <Text size='sm' color='black.200'>
            Your password has been changed successfully.
          </Text>
        </Stack>
        <Stack spacing='6'>
          <Button
            type='submit'
            isLoading={submitting}
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
