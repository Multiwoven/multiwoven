import { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';

import { SignUpPayload, signUp, AuthErrorResponse } from '@/services/authentication';
import Cookies from 'js-cookie';
import titleCase from '@/utils/TitleCase';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import { useMutation } from '@tanstack/react-query';
import { Mixpanel } from '@/mixpanel';
import { EVENTS } from '@/events-constants';
import { useConfigStore } from '@/enterprise/store/useConfigStore';
import { inviteSignUp, InviteSignUpPayload } from '@/enterprise/services/authentication';
import {
  BRAND_NAME,
  LOGO_URL,
  PRIVACY_POLICY_URL,
  TERMS_OF_SERVICE_URL,
} from '@/enterprise/app-constants';

import { SignUpAuthView } from '@/views/Authentication/AuthViews/SignUpAuthView';
import { Heading, Stack, Text } from '@chakra-ui/react';
import AuthCard from '@/views/Authentication/AuthCard';
import AuthFooter from '@/views/Authentication/AuthFooter';
import { useErrorToast } from '@/hooks/useErrorToast';

const SignUp = (): JSX.Element => {
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();
  const showToast = useCustomToast();
  const errorToast = useErrorToast();
  const [searchParams] = useSearchParams();

  // invite sign up flow params
  let isInviteSignupFlow = false;
  const workspaceName = searchParams.get('workspace_name');
  const invitationToken = searchParams.get('invitation_token');
  const invitedBy = searchParams.get('invited_by');
  const invitedUserEmail = searchParams.get('invited_user');

  if (workspaceName && invitationToken && invitedBy) {
    isInviteSignupFlow = true;
  }

  const { mutateAsync } = useMutation({
    mutationFn: (values: SignUpPayload) => signUp(values),
    mutationKey: ['signIn'],
  });

  const { mutateAsync: inviteSignupMutateAsync } = useMutation({
    mutationFn: (values: InviteSignUpPayload) => inviteSignUp(values),
    mutationKey: ['signIn'],
  });

  const handleSubmit = async (values: any) => {
    setSubmitting(true);
    try {
      const payload = { user: { ...values, invitation_token: invitationToken } };

      if (isInviteSignupFlow) {
        const result = await inviteSignupMutateAsync(payload);
        if (result.data?.attributes?.token) {
          const token = result?.data?.attributes.token;
          if (token) {
            Cookies.set('authToken', token, {
              secure: true,
              sameSite: 'Lax',
            });

            showToast({
              title: 'Account created.',
              status: CustomToastStatus.Success,
              duration: 3000,
              isClosable: true,
              position: 'bottom-right',
            });
            Mixpanel.track(EVENTS.SIGNUP_SUCCESS, {
              company_name: values.company_name,
              name: values.name,
              email: values.email,
            });

            navigate('/');
          } else {
            showToast({
              duration: 5000,
              isClosable: true,
              position: 'bottom-right',
              colorScheme: 'red',
              status: CustomToastStatus.Warning,
              title: titleCase('Auth token is invalid'),
            });
          }
        }
      } else {
        const result = await mutateAsync(values);

        if (result.data?.attributes) {
          showToast({
            title: 'Account created.',
            status: CustomToastStatus.Success,
            duration: 3000,
            isClosable: true,
            position: 'bottom-right',
          });
          Mixpanel.track(EVENTS.SIGNUP_SUCCESS, {
            company_name: values.company_name,
            name: values.name,
            email: values.email,
          });

          navigate('/sign-up/success?email=' + values.email);
        } else {
          result.errors?.forEach((error: AuthErrorResponse) => {
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
      }
    } catch (error) {
      errorToast('An error occured. Please try again later.', true, error, true);
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
      <AuthCard logoUrl={logoUrl} brandName={brandName}>
        <Stack spacing='8px' textAlign='center' mb='32px'>
          <Heading size='xs' fontWeight='semibold'>
            {isInviteSignupFlow ? "Let's activate your data" : `Get started with ${brandName}`}
          </Heading>
          {isInviteSignupFlow ? (
            <Text size='sm' color='black.200'>
              <Text as='span' fontWeight='bold'>
                {invitedBy}{' '}
              </Text>
              {`has invited you to use ${brandName} with them, in a workspace called `}
              <Text as='span' fontWeight='bold'>
                {workspaceName}
              </Text>
            </Text>
          ) : (
            <Text size='sm' color='black.200'></Text>
          )}
        </Stack>
        <SignUpAuthView
          logoUrl={logoUrl}
          brandName={brandName}
          handleSubmit={handleSubmit}
          submitting={submitting}
          privacyPolicyUrl={privacyPolicyUrl}
          termsOfServiceUrl={termsOfServiceUrl}
          isCompanyNameDisabled={isInviteSignupFlow}
          isEmailDisabled={isInviteSignupFlow}
          initialValues={{
            company_name: workspaceName || '',
            email: invitedUserEmail || '',
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
