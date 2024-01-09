import { useState } from 'react';
import { Formik, Form, ErrorMessage,FormikTouched, FormikErrors, FieldInputProps } from 'formik';
import * as Yup from 'yup';
import { useNavigate } from 'react-router-dom';
import { Box, Stack, HStack, Divider, FormLabel, Button, FormControl, Input, Heading, Text, Link, Container, Checkbox } from '@chakra-ui/react';
import MultiwovenIcon from '../../assets/images/icon.png';
import { login } from '@/services/common';
import { GoogleIcon } from './providerIcon';
import Cookies from 'js-cookie';

const LoginSchema = Yup.object().shape({
  email: Yup.string().email('Invalid email address').required('Email is required'),
  password: Yup.string().min(8, 'Password must be at least 8 characters').required('Password is required'),
});

interface LoginFormProps {
  getFieldProps: (nameOrOptions: string | { name: string; value?: any; onChange?: (e: any) => void; onBlur?: (e: any) => void }) => FieldInputProps<any>;
  touched: FormikTouched<any>;
  errors: FormikErrors<any>;
  submitting: boolean;
}

const LoginForm = ({ getFieldProps, touched, errors, submitting }: LoginFormProps) => (
  <Form>
    <FormControl isInvalid={!!(touched.email && errors.email)}>
      <FormLabel htmlFor="email">Email</FormLabel>
      <Input variant='outline' placeholder='Email' {...getFieldProps('email')} />
      <ErrorMessage name='email' />
    </FormControl>

    <FormControl mt={4} isInvalid={!!(touched.password && errors.password)}>
      <FormLabel htmlFor="password">Password</FormLabel>
      <Input id="password" type="password" placeholder="********" {...getFieldProps('password')} />
      <ErrorMessage name='password' />
    </FormControl>

    <HStack mt={4} justify="space-between">
      <Checkbox defaultChecked>Remember me</Checkbox>
      <Button variant="text" size="sm">
        Forgot password?
      </Button>
    </HStack>

    <Button mt={4} minW={'100%'} type='submit' isLoading={submitting} loadingText="Logging In">
      Sign in
    </Button>
  </Form>
);

const Login = () => {
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (values: any) => {
    setSubmitting(true)
    const result = await login(values);
    if (result.success) {
      const token = result?.response?.data?.token;
      Cookies.set('authToken', token);
      setSubmitting(false);
      navigate('/');
    } else {
      setSubmitting(false);
    }
  };

  return (
    <Formik
      initialValues={{ email: '', password: '' }}
      onSubmit={(values) => handleSubmit(values)}
      validationSchema={LoginSchema}
    >
      {({ getFieldProps, touched, errors }) => (
        <Container maxW="lg" py={{ base: '12', md: '24' }} px={{ base: '0', sm: '8' }}>
          <Stack spacing="8">
            <Stack spacing="6" alignItems={'center'}>
              <img src={MultiwovenIcon} width={55} />
              <Stack spacing={{ base: '2', md: '3' }} textAlign="center">
                <Heading size={{ base: 'xs', md: 'sm' }}>Log in to your account</Heading>
                <Text color="fg.muted">
                  Don't have an account? <Link href="/sign-up">Sign up</Link>
                </Text>
              </Stack>
            </Stack>
            <Box
              py={{ base: '0', sm: '8' }}
              px={{ base: '4', sm: '10' }}
              bg={{ base: 'transparent', sm: 'bg.surface' }}
              boxShadow={{ base: 'none', sm: 'md' }}
              borderRadius={{ base: 'none', sm: 'xl' }}
            >
              <Stack spacing="6">
                <LoginForm getFieldProps={getFieldProps} touched={touched} errors={errors} submitting={submitting} />
                <Stack spacing="6">
                  <HStack>
                    <Divider />
                    <Text textStyle="sm" whiteSpace="nowrap" color="fg.muted">
                      or continue with
                    </Text>
                    <Divider />
                  </HStack>
                  <Button variant="secondary" leftIcon={<GoogleIcon />}>
                    Sign in with Google
                  </Button>
                </Stack>
              </Stack>
            </Box>
          </Stack>
        </Container>
      )}
    </Formik>
  );
}

export default Login;
