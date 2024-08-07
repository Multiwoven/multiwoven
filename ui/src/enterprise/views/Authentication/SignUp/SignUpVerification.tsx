import { useSearchParams } from 'react-router-dom';
import AuthFooter from '@/views/Authentication/AuthFooter';
import { CustomToastStatus } from '@/components/Toast';
import { resendUserVerification } from '@/services/authentication';
import { useState } from 'react';
import useCustomToast from '@/hooks/useCustomToast';
import { useMutation } from '@tanstack/react-query';
import { SignUpVerificationAuthView } from '@/views/Authentication/AuthViews/SignUpVerificationAuthView';
import { useAPIErrorsToast, useErrorToast } from '@/hooks/useErrorToast';
import { useConfigStore } from '@/enterprise/store/useConfigStore';
import {
  BRAND_NAME,
  LOGO_URL,
  PRIVACY_POLICY_URL,
  TERMS_OF_SERVICE_URL,
} from '@/enterprise/app-constants';

const SignUpVerification = (): JSX.Element => {
  const [submitting, setSubmitting] = useState(false);
  const showToast = useCustomToast();
  const apiErrorToast = useAPIErrorsToast();
  const errorToast = useErrorToast();

  const [searchParams] = useSearchParams();
  const email = searchParams.get('email') || '';

  const { mutateAsync } = useMutation({
    mutationFn: (email: string) => resendUserVerification({ email }),
    mutationKey: ['verify-user'],
  });

  const handleEmailResend = async (email: string) => {
    setSubmitting(true);
    try {
      const result = await mutateAsync(email);

      if (result.data?.attributes) {
        showToast({
          title: result.data.attributes.message,
          status: CustomToastStatus.Success,
          duration: 3000,
          isClosable: true,
          position: 'bottom-right',
        });

        setSubmitting(false);
      } else {
        apiErrorToast(result.errors || []);
      }
    } catch (error) {
      errorToast('An error occured. Please try again later.', true, null, true);
    } finally {
      setSubmitting(false);
    }
  };

  const {
    logoUrl = LOGO_URL,
    brandName = BRAND_NAME,
    privacyPolicyUrl = PRIVACY_POLICY_URL,
    termsOfServiceUrl = TERMS_OF_SERVICE_URL,
  } = useConfigStore.getState().configs;
  return (
    <>
      <SignUpVerificationAuthView
        brandName={brandName}
        logoUrl={logoUrl}
        email={email}
        handleEmailResend={() => handleEmailResend(email)}
        submitting={submitting}
      />

      <AuthFooter
        brandName={brandName}
        privacyPolicyUrl={privacyPolicyUrl}
        termsOfServiceUrl={termsOfServiceUrl}
      />
    </>
  );
};

export default SignUpVerification;
