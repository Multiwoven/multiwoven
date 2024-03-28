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
  Checkbox,
} from '@chakra-ui/react';
import MultiwovenIcon from '@/assets/images/icon-white.svg';
import { SignInErrorResponse, SignInPayload, signIn } from '@/services/authentication';
import Cookies from 'js-cookie';
import titleCase from '@/utils/TitleCase';
import AuthFooter from '../AuthFooter';
import HiddenInput from '@/components/HiddenInput';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import mwTheme from '@/chakra.config';

const SignInSchema = Yup.object().shape({
  email: Yup.string().email('Please enter a valid email address').required('Email is required'),
  password: Yup.string()
    .min(8, 'Password must be at least 8 characters')
    .required('Password is required'),
});

interface SignInFormProps {
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
}: SignInFormProps) => (
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
}: SignInFormProps) => (
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

const SignIn = (): JSX.Element => {
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();
  const showToast = useCustomToast();

  const handleSubmit = async (values: SignInPayload) => {
    setSubmitting(true);
    const result = await signIn(values);

    if (result.data?.attributes) {
      const token = result.data.attributes.token;
      Cookies.set('authToken', token, {
        secure: true,
        sameSite: 'Lax',
      });
      result.data.attributes.token;
      setSubmitting(false);
      showToast({
        duration: 3000,
        isClosable: true,
        position: 'bottom-right',
        title: 'Signed In',
        status: CustomToastStatus.Success,
      });
      navigate('/', { replace: true });
    } else {
      setSubmitting(false);
      result.data?.errors?.map((error: SignInErrorResponse) => {
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
  };

  const { logoUrl, brandName } = mwTheme;

  return (
    <>
      <Flex justify='center' w='100%' minHeight='90vh' alignItems='center' overflowY='auto'>
        <Formik
          initialValues={{
            email: '',
            password: '',
          }}
          onSubmit={(values) => handleSubmit(values)}
          validationSchema={SignInSchema}
        >
          {({ getFieldProps, touched, errors }) => (
            <Form>
              <Container width={{ base: '400px', sm: '500px' }} py='6'>
                <Stack>
                  <Box position='relative' top='12'>
                    <Box
                      bgColor={logoUrl ? 'gray.100' : 'brand.400'}
                      h='80px'
                      w={logoUrl ? '150px' : '80px'}
                      display='flex'
                      justifyContent='center'
                      alignItems='center'
                      borderRadius='11px'
                      mx='auto'
                    >
                      <Image
                        src={logoUrl ? logoUrl : MultiwovenIcon}
                        width={logoUrl ? '100%' : '45px'}
                        alt={`${brandName} Logo in White`}
                      />
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
                        {"Let's activate your data"}
                      </Heading>
                      <Text size='sm' color='black.200'>
                        {`Sign In to your ${brandName} account`}
                      </Text>
                    </Stack>
                    <Stack spacing='6'>
                      <Stack spacing='3'>
                        <FormField
                          placeholder='Enter email'
                          name='email'
                          type='text'
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
                        <PasswordField
                          placeholder='Enter password'
                          name='password'
                          type='password'
                          getFieldProps={getFieldProps}
                          touched={touched}
                          errors={errors}
                        />
                        ={' '}
                        <HStack justify='space-between'>
                          <Checkbox
                            defaultChecked
                            _checked={{
                              '& .chakra-checkbox__control': {
                                background: 'brand.400',
                                borderColor: 'brand.400',
                              },
                              '& .chakra-checkbox__control:hover': {
                                background: 'brand.400',
                                borderColor: 'brand.400',
                              },
                            }}
                            iconSize='12px'
                            size='sm'
                          >
                            <Text size='xs' fontWeight='medium'>
                              Stay signed in
                            </Text>
                          </Checkbox>
                          <Text size='xs' color='brand.400' fontWeight='semibold'>
                            Forgot Password?
                          </Text>
                        </HStack>
                      </Stack>
                      <Stack spacing='6'>
                        <Button
                          type='submit'
                          isLoading={submitting}
                          loadingText='Signing In'
                          variant='solid'
                          width='full'
                        >
                          Sign In
                        </Button>
                      </Stack>
                      <HStack spacing={1} justify='center'>
                        <Text color='black.500' size='xs' fontWeight='medium'>
                          {"Don't have an account?"}{' '}
                        </Text>
                        <Link to='/sign-up'>
                          <Text color='brand.400' size='xs' fontWeight='semibold'>
                            Sign Up
                          </Text>
                        </Link>
                      </HStack>
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

export default SignIn;
