import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import mwTheme from '@/chakra.config';
import AuthFooter from '../AuthFooter';
import { CustomToastStatus } from '@/components/Toast';
import { resendUserVerification, verifyUser } from '@/services/authentication';
import useCustomToast from '@/hooks/useCustomToast';
import { useMutation } from '@tanstack/react-query';
import { VerifyUserSuccessAuthView } from '../AuthViews/VerifyUserSuccessAuthView';
import { VerifyUserFailedAuthView } from '../AuthViews/VerifyUserFailedAuthView';
import Loader from '@/components/Loader';
import { useAPIErrorsToast, useErrorToast } from '@/hooks/useErrorToast';

const VerifyUser = (): JSX.Element => {
  const [success, setSuccess] = useState(false);
  const [submitting, setSubmitting] = useState(true); // Add this to handle the final state

  const showToast = useCustomToast();
  const errorToast = useAPIErrorsToast();

  const [searchParams] = useSearchParams();
  const confirmation_token = searchParams.get('confirmation_token');
  const email = searchParams.get('email') || '';

  const { mutateAsync } = useMutation({
    mutationFn: (email: string) => resendUserVerification({ email }),
    mutationKey: ['resend-verification'],
  });

  const { logoUrl, brandName, privacyPolicyUrl, termsOfServiceUrl } = mwTheme;

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
        errorToast(result.errors || []);
      }
    } catch (error) {
      useErrorToast(true, error, true, 'An error occured. Please try again later.');
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
