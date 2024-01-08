import { Formik, Form, ErrorMessage } from 'formik';
import * as Yup from 'yup';
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';
import { Box, Stack, HStack, Divider, FormLabel, Button, FormControl, Input, Heading, Text, Link, Container, Checkbox } from '@chakra-ui/react';
import MultiwovenIcon from '../../assets/images/icon.png';
import { login } from '@/services/common';
import Cookies from 'js-cookie';
import { GoogleIcon } from './providerIcon'

const LoginSchema = Yup.object().shape({
  email: Yup.string()
    .email('Invalid email address')
    .required('Email is required'),
  password: Yup.string()
    .min(8, 'Password must be at least 8 characters')
    .required('Password is required'),
});


const Login = () => {
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (values: any) => {
    setSubmitting(true)
    const result = await login(values);
    if (result.success) {
      const token = result?.response?.data?.token;
      Cookies.set('authToken', token, {sameSite:"Strict"});
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
        <Form>
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
                  <Stack spacing="5">
                    <FormControl isInvalid={!!(touched.email && errors.email)}>
                      <FormLabel htmlFor="email">Email</FormLabel>
                      <Input variant='outline' placeholder='Email' {...getFieldProps('email')} />
                      <ErrorMessage name='email' />
                    </FormControl>

                    <FormControl isInvalid={!!(touched.password && errors.password)}>
                      <FormLabel htmlFor="password">Password</FormLabel>
                      <Input id="password" type="password" placeholder="********" {...getFieldProps('password')} />
                      <ErrorMessage name='password' />
                    </FormControl>
                  </Stack>
                  <HStack justify="space-between">
                    <Checkbox defaultChecked>Remember me</Checkbox>
                    <Button variant="text" size="sm">
                      Forgot password?
                    </Button>
                  </HStack>
                  <Stack spacing="6">
                    <Button type='submit' isLoading={submitting} loadingText="Logging In">
                      Sign in
                    </Button>
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
                    {/* <OAuthButtonGroup /> */}
                  </Stack>
                </Stack>
              </Box>
            </Stack>
          </Container>
        </Form>
      )}
    </Formik>
  )
}

export default Login;