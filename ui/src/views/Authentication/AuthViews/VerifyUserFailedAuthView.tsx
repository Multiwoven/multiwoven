import AuthCard from '../AuthCard';
import { Button, Heading, Stack, Text } from '@chakra-ui/react';
import { VerifyUserFailedAuthViewProps } from '../types';

export const VerifyUserFailedAuthView = ({
  brandName,
  logoUrl,
  resendEmail,
}: VerifyUserFailedAuthViewProps) => (
  <>
    <AuthCard logoUrl={logoUrl} brandName={brandName}>
      <Stack spacing='8px' textAlign='center' mb='32px'>
        <Heading size='xs' fontWeight='semibold'>
          Link expired{' '}
        </Heading>
        <Text size='sm' color='black.200'>
          To verify your email and complete sign up, please resend the verification email.
        </Text>
      </Stack>
      <Stack spacing='6'>
        <Button
          type='submit'
          loadingText='Submitting'
          variant='shell'
          width='full'
          onClick={resendEmail}
        >
          Resend Email
        </Button>
      </Stack>
    </AuthCard>
  </>
);
