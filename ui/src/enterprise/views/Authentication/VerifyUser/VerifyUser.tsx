import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import AuthFooter from '@/views/Authentication/AuthFooter';
import { CustomToastStatus } from '@/components/Toast';
import { resendUserVerification, verifyUser } from '@/services/authentication';
import useCustomToast from '@/hooks/useCustomToast';
import { useMutation } from '@tanstack/react-query';
import { VerifyUserSuccessAuthView } from '@/views/Authentication/AuthViews/VerifyUserSuccessAuthView';
import { VerifyUserFailedAuthView } from '@/views/Authentication/AuthViews/VerifyUserFailedAuthView';
import Loader from '@/components/Loader';
import { useConfigStore } from '@/enterprise/store/useConfigStore';
import {
  BRAND_NAME,
  LOGO_URL,
  PRIVACY_POLICY_URL,
  TERMS_OF_SERVICE_URL,
} from '@/enterprise/app-constants';
import { useAPIErrorsToast, useErrorToast } from '@/hooks/useErrorToast';

const VerifyUser = (): JSX.Element => {
  const [success, setSuccess] = useState(false);
  const [submitting, setSubmitting] = useState(true); // Add this to handle the final state

  const showToast = useCustomToast();
  const apiErrorToast = useAPIErrorsToast();
  const errorToast = useErrorToast();

  const [searchParams] = useSearchParams();
  const confirmation_token = searchParams.get('confirmation_token');
  const email = searchParams.get('email') || '';

  const { mutateAsync } = useMutation({
    mutationFn: (email: string) => resendUserVerification({ email }),
    mutationKey: ['resend-verification'],
  });

  const {
    logoUrl = LOGO_URL,
    brandName = BRAND_NAME,
    privacyPolicyUrl = PRIVACY_POLICY_URL,
    termsOfServiceUrl = TERMS_OF_SERVICE_URL,
  } = useConfigStore.getState().configs;

  const verifyUserToken = async () => {
    if (!confirmation_token) {
      setSubmitting(false);
      return;
    }

    try {
      const result = await verifyUser(confirmation_token);
      if (result.data?.attributes) {
        showToast({
          title: 'Account verified.',
          status: CustomToastStatus.Success,
          duration: 3000,
          isClosable: true,
          position: 'bottom-right',
        });
        setSuccess(true);
      } else {
        apiErrorToast(result.errors || []);
      }
    } catch (error) {
      errorToast('An error occured. Please try again later.', true, null, true);
    } finally {
      setSubmitting(false);
    }
  };

  useEffect(() => {
    verifyUserToken();
  }, []);

  if (submitting) {
    return <Loader />;
  }

  return (
    <>
      {success ? (
        <VerifyUserSuccessAuthView logoUrl={logoUrl} brandName={brandName} />
      ) : (
        <VerifyUserFailedAuthView
          logoUrl={logoUrl}
          brandName={brandName}
          resendEmail={() => mutateAsync(email)}
        />
      )}
      <AuthFooter
        brandName={brandName}
        privacyPolicyUrl={privacyPolicyUrl}
        termsOfServiceUrl={termsOfServiceUrl}
      />
    </>
  );
};

export default VerifyUser;
