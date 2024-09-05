import { useNavigate } from 'react-router-dom';
import { Stack, Heading } from '@chakra-ui/react';

import mwTheme from '@/chakra.config';
import AuthFooter from '../AuthFooter';
import { SignUpAuthView } from '@/views/Authentication/AuthViews/SignUpAuthView';
import AuthCard from '../AuthCard';
import { CustomToastStatus } from '@/components/Toast';
import { SignUpPayload, signUp } from '@/services/authentication';
import { useState } from 'react';
import useCustomToast from '@/hooks/useCustomToast';
import { useMutation } from '@tanstack/react-query';

import { useAPIErrorsToast, useErrorToast } from '@/hooks/useErrorToast';
// import isValidEmailDomain from '@/utils/isValidEmailDomain';

const SignUp = (): JSX.Element => {
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();
  const showToast = useCustomToast();
  const apiErrorToast = useAPIErrorsToast();
  const errorToast = useErrorToast();

  const { mutateAsync } = useMutation({
    mutationFn: (values: SignUpPayload) => signUp(values),
    mutationKey: ['signUp'],
  });

  const handleSubmit = async (values: any) => {
    setSubmitting(true);
    try {
      const result = await mutateAsync(values);

      if (result.data?.attributes) {
        showToast({
          title: 'Account created.',
          status: CustomToastStatus.Success,
          duration: 3000,
          isClosable: true,
          position: 'bottom-right',
        });

        navigate(`/sign-up/success?email=${values.email}`);
      } else {
        apiErrorToast(result.errors || []);
      }
    } catch (error) {
      errorToast('An error occured. Please try again later.', true, null, true);
    } finally {
      setSubmitting(false);
    }
  };

  const { logoUrl, brandName, privacyPolicyUrl, termsOfServiceUrl } = mwTheme;

  return (
    <>
      <AuthCard logoUrl={logoUrl} brandName={brandName}>
        <Stack spacing='8px' textAlign='center' mb='32px'>
          <Heading size='xs' fontWeight='semibold'>
            Get started with {brandName}
          </Heading>
        </Stack>
        <SignUpAuthView
          logoUrl={logoUrl}
          brandName={brandName}
          handleSubmit={handleSubmit}
          submitting={submitting}
          privacyPolicyUrl={privacyPolicyUrl}
          termsOfServiceUrl={termsOfServiceUrl}
          initialValues={{
            company_name: '',
            email: '',
            name: '',
            password: '',
            password_confirmation: '',
          }}
        />
      </AuthCard>
      <AuthFooter
        brandName={brandName}
        privacyPolicyUrl={privacyPolicyUrl}
        termsOfServiceUrl={termsOfServiceUrl}
      />
    </>
  );
};

export default SignUp;
