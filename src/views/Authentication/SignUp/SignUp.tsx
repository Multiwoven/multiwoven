import { useState } from 'react';
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
} from '@chakra-ui/react';
import MultiwovenIcon from '@/assets/images/icon-white.svg';
import { signUp } from '@/services/authentication';
import Cookies from 'js-cookie';
import titleCase from '@/utils/TitleCase';
import AuthFooter from '../AuthFooter';
import HiddenInput from '@/components/HiddenInput';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';

const SignUpSchema = Yup.object().shape({
  company_name: Yup.string().required('Company name is required'),
  name: Yup.string().required('Name is required'),
  email: Yup.string().email('Invalid email address').required('Email is required'),
  password: Yup.string()
    .min(8, 'Password must be at least 8 characters')
    .required('Password is required'),
  password_confirmation: Yup.string()
    .oneOf([Yup.ref('password'), ''], 'Passwords must match')
    .required('Confirm Password is required'),
});

interface SignUpFormProps {
  name: string;
  type: string;
  placeholder?: string;
  getFieldProps: (
    nameOrOptions:
      | string
      | {
          name: string;
          value?: any;
          onChange?: (e: any) => void;
          onBlur?: (e: any) => void;
        },
  ) => FieldInputProps<any>;
  touched: FormikTouched<any>;
  errors: FormikErrors<any>;
}

const FormField = ({
  name,
  type,
  getFieldProps,
  touched,
  errors,
  placeholder,
}: SignUpFormProps) => (
  <FormControl isInvalid={!!(touched[name] && errors[name])}>
    <Input
      variant='outline'
      placeholder={placeholder}
      _placeholder={{ color: 'black.100' }}
      type={type}
      {...getFieldProps(name)}
      fontSize='sm'
      color='black.500'
      focusBorderColor='brand.400'
    />
    <Text size='xs' color='red.500' mt={2}>
      <ErrorMessage name={name} />
    </Text>
  </FormControl>
);

const PasswordField = ({
  name,
  type,
  getFieldProps,
  touched,
  errors,
  placeholder,
}: SignUpFormProps) => (
  <FormControl isInvalid={!!(touched[name] && errors[name])}>
    <HiddenInput
      variant='outline'
      placeholder={placeholder}
      _placeholder={{ color: 'black.100' }}
      type={type}
      {...getFieldProps(name)}
      fontSize='sm'
      color='black.500'
      focusBorderColor='brand.400'
    />
    <Text size='xs' color='red.500' mt={2}>
      <ErrorMessage name={name} />
    </Text>
  </FormControl>
);

type SignUpErrors = {
  source: {
    [key: string]: string;
  };
};

const SignUp = (): JSX.Element => {
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();
  const showToast = useCustomToast();

  const handleSubmit = async (values: any) => {
    setSubmitting(true);
    const result = await signUp(values);

    if (result.data?.attributes) {
      const token = result.data.attributes.token;
      Cookies.set('authToken', token, {
        secure: true,
        sameSite: 'Lax',
      });
      result.data.attributes.token;
      setSubmitting(false);
      showToast({
        title: 'Account created.',
        status: CustomToastStatus.Success,
        duration: 3000,
        isClosable: true,
        position: 'bottom-right',
      });
      navigate('/');
    } else {
      setSubmitting(false);
      result.data?.errors?.map((error: SignUpErrors) => {
        Object.keys(error.source).map((error_key) => {
          showToast({
            title: titleCase(error_key) + ' ' + error.source[error_key],
            status: CustomToastStatus.Warning,
            duration: 5000,
            isClosable: true,
            position: 'bottom-right',
            colorScheme: 'red',
          });
        });
      });
    }
  };

  return (
    <>
      <Flex justify='center' w='100%' minHeight='90vh' alignItems='center' overflowY='auto'>
        <Formik
          initialValues={{
            company_name: '',
            name: '',
            email: '',
            password: '',
            password_confirmation: '',
          }}
          onSubmit={(values) => handleSubmit(values)}
          validationSchema={SignUpSchema}
        >
          {({ getFieldProps, touched, errors }) => (
            <Form>
              <Container width={{ base: '400px', sm: '500px' }} py='6'>
                <Stack>
                  <Box position='relative' top='12'>
                    <Box
                      bgColor='brand.400'
                      h='80px'
                      w='80px'
                      display='flex'
                      justifyContent='center'
                      alignItems='center'
                      borderRadius='11px'
                      mx='auto'
                    >
                      <Image src={MultiwovenIcon} width='45px' alt='Multiwoven Logo in White' />
                    </Box>
                  </Box>
                  <Box
                    padding='20px'
                    borderRadius='10px'
                    border='1px'
                    borderColor='gray.400'
                    paddingTop='60px'
                  >
                    <Stack spacing='8px' textAlign='center' mb='32px'>
                      <Heading size='xs' fontWeight='semibold'>
                        Get started with Multiwoven
                      </Heading>
                      <Text size='sm' color='black.200'>
                        Sign up and create your account
                      </Text>
                    </Stack>
                    <Stack spacing='20px'>
                      <Stack spacing='16px'>
                        <FormField
                          placeholder='Enter company name'
                          name='company_name'
                          type='text'
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
                        <FormField
                          placeholder='Enter name'
                          name='name'
                          type='text'
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
                        <FormField
                          placeholder='Enter email'
                          name='email'
                          type='text'
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
                        <PasswordField
                          placeholder='Choose password'
                          name='password'
                          type='password'
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
                        <PasswordField
                          placeholder='Confirm password'
                          name='password_confirmation'
                          type='password'
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
                        <HStack spacing={1}>
                          <Text color='black.200' size='xs' fontWeight='regular'>
                            By creating an account, I agree to the{' '}
                          </Text>
                          <Link to='https://multiwoven.com/terms' target='_blank'>
                            <Text color='brand.400' size='xs' fontWeight='medium'>
                              Terms
                            </Text>
                          </Link>
                          <Text color='black.200' size='xs' fontWeight='regular'>
                            and
                          </Text>
                          <Link to='https://multiwoven.com/privacy' target='_blank'>
                            <Text color='brand.400' size='xs' fontWeight='medium'>
                              Privacy Policy
                            </Text>
                          </Link>
                        </HStack>
                      </Stack>
                      <Stack spacing='6'>
                        <Button
                          type='submit'
                          isLoading={submitting}
                          loadingText='Creating Account'
                          variant='solid'
                          width='full'
                        >
                          Create Account
                        </Button>
                        <HStack spacing={1} justify='center'>
                          <Text color='black.500' size='xs' fontWeight='medium'>
                            Do you have an account?{' '}
                          </Text>
                          <Link to='/sign-in'>
                            <Text color='brand.400' size='xs' fontWeight='semibold'>
                              Sign In
                            </Text>
                          </Link>
                        </HStack>
                      </Stack>
                    </Stack>
                  </Box>
                </Stack>
              </Container>
            </Form>
          )}
        </Formik>
      </Flex>
      <AuthFooter />
    </>
  );
};

export default SignUp;
