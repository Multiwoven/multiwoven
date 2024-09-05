import { useState } from 'react';
import { ResetPasswordPayload, resetPassword } from '@/services/authentication';
import titleCase from '@/utils/TitleCase';
import AuthFooter from '../AuthFooter';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import { useMutation } from '@tanstack/react-query';

import { ErrorResponse } from '@/services/common';

import { ResetPasswordAuthView } from '@/views/Authentication/AuthViews/ResetPasswordAuthView';
import { ResetPasswordSuccessAuthView } from '@/views/Authentication/AuthViews/ResetPasswordSuccessAuthView';
import { useSearchParams } from 'react-router-dom';
import mwTheme from '@/chakra.config';
import { ResetPasswordFormPayload } from '../types';

const ResetPassword = (): JSX.Element => {
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);

  const showToast = useCustomToast();

  const [searchParams] = useSearchParams();
  const token = searchParams.get('reset_password_token');

  const { mutateAsync } = useMutation({
    mutationFn: (values: ResetPasswordPayload) => resetPassword(values),
    mutationKey: ['Reset-password'],
  });

  const handleSubmit = async (values: ResetPasswordFormPayload) => {
    setSubmitting(true);

    if (token !== null) {
      const payload = { ...values, reset_password_token: token };
      try {
        const result = await mutateAsync(payload);

        if (result.data?.attributes.message) {
          showToast({
            duration: 3000,
            isClosable: true,
            position: 'bottom-right',
            title: result.data.attributes.message,
            status: CustomToastStatus.Success,
          });
          setSuccess(true);
        } else {
          result?.errors?.forEach((error: ErrorResponse) => {
            showToast({
              duration: 5000,
              isClosable: true,
              position: 'bottom-right',
              colorScheme: 'red',
              status: CustomToastStatus.Warning,
              title: titleCase(error.detail) + ' Please try resetting your password again.',
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
    }
  };

  const { logoUrl, brandName, privacyPolicyUrl, termsOfServiceUrl } = mwTheme;

  return (
    <>
      {success ? (
        <ResetPasswordSuccessAuthView
          logoUrl={logoUrl}
          brandName={brandName}
          submitting={submitting}
        />
      ) : (
        <ResetPasswordAuthView
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

export default ResetPassword;
