import AuthCard from '../AuthCard';
import { Button, Heading, Stack, Text } from '@chakra-ui/react';
import { VerificationAuthViewProps } from '../types';

export const SignUpVerificationAuthView = ({
  brandName,
  logoUrl,
  email,
  handleEmailResend,
  submitting,
}: VerificationAuthViewProps) => (
  <>
    <AuthCard logoUrl={logoUrl} brandName={brandName}>
      <Stack spacing='8px' textAlign='center' mb='32px'>
        <Heading size='xs' fontWeight='semibold'>
          Check your email
        </Heading>
        <Text size='sm' color='black.200'>
          To complete sign up, click the verification button in the email we sent to <b>{email}</b>.
        </Text>
      </Stack>
      <Stack spacing='6'>
        <Button
          type='submit'
          isLoading={submitting}
          loadingText='Submitting'
          variant='shell'
          width='full'
          onClick={() => handleEmailResend(email)}
        >
          Resend Email
        </Button>
      </Stack>
    </AuthCard>
  </>
);
