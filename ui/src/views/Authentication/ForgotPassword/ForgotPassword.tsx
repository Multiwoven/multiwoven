import { useState } from 'react';
import { ForgotPasswordPayload, forgotPassword } from '@/services/authentication';
import titleCase from '@/utils/TitleCase';
import AuthFooter from '../AuthFooter';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import { useMutation } from '@tanstack/react-query';

import { ForgotPasswordAuthView } from '@/views/Authentication/AuthViews/ForgotPasswordAuthView';

import { ErrorResponse } from '@/services/common';
import { ForgotPasswordSuccessAuthView } from '@/views/Authentication/AuthViews/ForgotPasswordSuccessAuthView';
import mwTheme from '@/chakra.config';

const ForgotPassword = (): JSX.Element => {
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [userEmail, setUserEmail] = useState<string>('');

  const showToast = useCustomToast();

  const { mutateAsync } = useMutation({
    mutationFn: (values: ForgotPasswordPayload) => forgotPassword(values),
    mutationKey: ['forgot-password'],
  });

  const handleSubmit = async (values: ForgotPasswordPayload) => {
    setSubmitting(true);
    try {
      const result = await mutateAsync(values);

      if (result.data?.attributes.message) {
        showToast({
          duration: 3000,
          isClosable: true,
          position: 'bottom-right',
          title: result.data.attributes.message,
          status: CustomToastStatus.Success,
        });
        setUserEmail(values.email);
        setSuccess(true);
      } else {
        result?.errors?.forEach((error: ErrorResponse) => {
          showToast({
            duration: 5000,
            isClosable: true,
            position: 'bottom-right',
            colorScheme: 'red',
            status: CustomToastStatus.Warning,
            title: titleCase(error.detail),
          });
        });
      }
    } catch (error) {
      showToast({
        duration: 3000,
        isClosable: true,
        position: 'bottom-right',
        title: 'There was an error connecting to the server. Please try again later.',
        status: CustomToastStatus.Error,
      });
    } finally {
      setSubmitting(false);
    }
  };

  const { logoUrl, brandName, privacyPolicyUrl, termsOfServiceUrl } = mwTheme;

  return (
    <>
      {success ? (
        <ForgotPasswordSuccessAuthView
          logoUrl={logoUrl}
          brandName={'success'}
          handleEmailResend={handleSubmit}
          submitting={submitting}
          email={userEmail}
        />
      ) : (
        <ForgotPasswordAuthView
          logoUrl={logoUrl}
          brandName={brandName}
          handleSubmit={handleSubmit}
          submitting={submitting}
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

export default ForgotPassword;
