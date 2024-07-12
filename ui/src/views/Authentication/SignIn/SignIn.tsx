import { useState } from 'react';
<<<<<<< HEAD
import { Formik, Form, ErrorMessage, FormikTouched, FormikErrors, FieldInputProps } from 'formik';
import * as Yup from 'yup';
import { Link, useNavigate } from 'react-router-dom';
import {
  Box,
  Button,
  FormControl,
  Input,
  Heading,
  Text,
  Container,
  Stack,
  Flex,
  HStack,
  Image,
  Checkbox,
} from '@chakra-ui/react';
import MultiwovenIcon from '@/assets/images/icon-white.svg';
import { SignInErrorResponse, SignInPayload, signIn } from '@/services/authentication';
=======
import { useNavigate } from 'react-router-dom';
import { AuthErrorResponse, SignInPayload, signIn } from '@/services/authentication';
>>>>>>> 9f11d025 (refactor(CE): moved common elements of sign up and sign in to separate views)
import Cookies from 'js-cookie';
import titleCase from '@/utils/TitleCase';
import AuthFooter from '../AuthFooter';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import mwTheme from '@/chakra.config';
import { useMutation } from '@tanstack/react-query';
import { SignInAuthView } from '../AuthViews/SignInAuthView';

const SignIn = (): JSX.Element => {
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();
  const showToast = useCustomToast();

  const { mutateAsync } = useMutation({
    mutationFn: (values: SignInPayload) => signIn(values),
    mutationKey: ['signIn'],
  });

  const handleSubmit = async (values: SignInPayload) => {
    setSubmitting(true);
    try {
      const result = await mutateAsync(values);

      if (result.data?.attributes) {
        const token = result.data.attributes.token;
        Cookies.set('authToken', token, { secure: true, sameSite: 'Lax' });

        showToast({
          duration: 3000,
          isClosable: true,
          position: 'bottom-right',
          title: 'Signed In',
          status: CustomToastStatus.Success,
        });
        navigate('/', { replace: true });
      } else {
        result.data?.errors?.forEach((error: SignInErrorResponse) => {
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

  const { logoUrl, brandName } = mwTheme;

  return (
    <>
      <SignInAuthView
        logoUrl={logoUrl}
        brandName={brandName}
        handleSubmit={handleSubmit}
        submitting={submitting}
      />
      <AuthFooter />
    </>
  );
};

export default SignIn;
