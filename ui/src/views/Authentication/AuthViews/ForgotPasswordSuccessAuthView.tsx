import AuthCard from '../AuthCard';
import { Button, Heading, Stack, Text } from '@chakra-ui/react';

type ForgotPasswordSuccessAuthViewProps = {
  brandName: string;
  logoUrl: string;
  email: string;
  handleEmailResend: (values: any) => void;
  submitting: boolean;
};

export const ForgotPasswordSuccessAuthView = ({
  brandName,
  logoUrl,
  email,
  handleEmailResend,
  submitting,
}: ForgotPasswordSuccessAuthViewProps) => {
  return (
    <>
      <AuthCard logoUrl={logoUrl} brandName={brandName}>
        <Stack spacing='8px' textAlign='center' mb='32px'>
          <Heading size='xs' fontWeight='semibold'>
            Check your email
          </Heading>
          <Text size='sm' color='black.200'>
            Please check the email address <b>{email}</b> for instructions to reset your password.
          </Text>
        </Stack>
        <Stack spacing='6'>
          <Button
            type='submit'
            isLoading={submitting}
            loadingText='Submitting'
            variant='shell'
            width='full'
            onClick={() => handleEmailResend({ email: email })}
          >
            Resend Email
          </Button>
        </Stack>
      </AuthCard>
    </>
  );
};
