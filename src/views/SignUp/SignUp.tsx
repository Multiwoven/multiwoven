import { Formik, Form, ErrorMessage } from 'formik';
import * as Yup from 'yup';
import { Link as RouterLink, useNavigate } from 'react-router-dom';
import { Box, Button, FormControl, Input, Heading, Text, Link, Container, Stack, FormLabel, HStack, Checkbox, Divider } from '@chakra-ui/react';
import MultiwovenIcon from '../../assets/images/icon.png';
import AlertPopUp, { alertMessage } from '@/components/Alerts/Alerts';

import { useState } from 'react';
import signUp from '@/services/sign-up';
import { GoogleIcon } from '../Login/providerIcon';

const SignUpSchema = Yup.object().shape({
    name: Yup.string()
        .required('Name is required'),
    email: Yup.string()
        .email('Invalid email address')
        .required('Email is required'),
    password: Yup.string()
        .min(8, 'Password must be at least 8 characters')
        .required('Password is required'),
    password_confirmation: Yup.string()
        .oneOf([Yup.ref('password'), ''], 'Passwords must match')
        .required('Confirm Password is required'),
});

const SignUp = () => {
    let message = alertMessage;
    const [messages, setMessages] = useState({ 
        show: false, 
        alertMessage: message
    });

    const [submitting, setSubmitting] = useState(false);
    
    const navigate = useNavigate();
    
    const handleSubmit = async (values: any) => {
        setMessages({ show: false, alertMessage: message });
        setSubmitting(true)

        const result = await signUp(values);

        if (result.success) {
            sessionStorage.setItem("userEmail", values.email);
            setSubmitting(false)
            navigate('/account-verify');
        } else {
            message = {
                status: 'error',
                description: result.error || ["Some error has occured"]
            };
            setSubmitting(false)
            setMessages({ show: true, alertMessage: message });
        }
    };

    return (
        // <>
        //     <Container display='flex' flexDir='column' justifyContent='center' maxW='650' minH='100vh' className='flex flex-col align-center justify-center'>
        //         <div className='top_side_back'></div>
        //         <div className='bottom_side_back'></div>
        //         <Box width='100%' className="flex min-h-full flex-1 flex-col align-center justify-center py-12 sm:px-6 lg:px-8">
        //             <Box display='flex' justifyContent='center' className="sm:mx-auto sm:w-full sm:max-w-sm">
        //                 <Image
        //                     maxW="300px"
        //                     w="95%"
        //                     src={MultiwovenLogo}
        //                     alt="Multiwoven"
        //                 />

        //             </Box>

        //             <Box mt="14" className="sm:mx-auto sm:w-full sm:max-w-[480px]">
        //                 <Box bg="white" border='1px' borderColor="border" px="24" py="12" rounded="lg" className="sm:px-12">
        //                     <Heading fontSize='40px' as="h2" mt="0" mb='10' fontWeight="normal" textAlign="center" >
        //                         Create an account
        //                     </Heading>
        //                     { messages.show ? <AlertPopUp {...messages.alertMessage}/> : <></> }
        //                     <Formik
        //                         initialValues={{ name: '', email: '', password: '', password_confirmation: '' }}
        //                         validationSchema={SignUpSchema}
        //                         onSubmit={(values) => handleSubmit(values)}

        //                     >
        //                         {({ getFieldProps, touched, errors }) => (
        //                             <Form>
        //                                 <FormControl mb='24px' id="name" isInvalid={!!(touched.name && errors.name)}>
        //                                     <Input variant='outline' placeholder='Name' {...getFieldProps('name')} />
        //                                     <ErrorMessage name='name' />
        //                                 </FormControl>

        //                                 <FormControl mb='24px' id="email" isInvalid={!!(touched.email && errors.email)}>
        //                                     <Input variant='outline' placeholder='Email' {...getFieldProps('email')} />
        //                                     <ErrorMessage name='email' />
        //                                 </FormControl>

        //                                 <FormControl mb='24px' id="password" isInvalid={!!(touched.password && errors.password)}>
        //                                     <Input type="password" placeholder='Password' {...getFieldProps('password')} />
        //                                     <ErrorMessage name='password'  />
        //                                 </FormControl>

        //                                 <FormControl mb='8px' id="password_confirmation" isInvalid={!!(touched.password_confirmation && errors.password_confirmation)}>
        //                                     <Input type="password" placeholder='Confirm Password' {...getFieldProps('password_confirmation')} />
        //                                     <ErrorMessage name='password_confirmation'  />
        //                                 </FormControl>
        //                                 <Text mt="0" mb='24px' textAlign="left" fontSize="sm" color="gray.500">
        //                                     At least 8 characters long
        //                                 </Text>
        //                                 <Button isLoading={submitting} loadingText="Creating Account" type="submit" background="secondary" color='white' width="full" _hover={{ background: "secondary" }}>
        //                                     Create Account
        //                                 </Button>
        //                             </Form>
        //                         )}
        //                     </Formik>
        //                     <Text mt="6" textAlign="left" fontSize="sm" color="gray.500">
        //                         Already have an account?{' '}
        //                         <Link as={RouterLink} to="/login" color="hyperlink" _hover={{ color: 'hyperlink' }}>
        //                             Sign In
        //                         </Link>
        //                     </Text>
        //                 </Box>
        //             </Box>
        //         </Box>
        //     </Container>
        // </>
        <Formik
            initialValues={{ name:'', email: '', password: '', password_confirmation:'' }}
            onSubmit={(values) => handleSubmit(values)}
            validationSchema={SignUpSchema}
        >
      {({ getFieldProps, touched, errors }) => (
        <Form>
          <Container maxW="lg" py={{ base: '12', md: '24' }} px={{ base: '0', sm: '8' }}>
            <Stack spacing="8">
              <Stack spacing="6" alignItems={'center'}>
                <img src={MultiwovenIcon} width={55} />
                <Stack spacing={{ base: '2', md: '3' }} textAlign="center">
                  <Heading size={{ base: 'xs', md: 'sm' }}>Create an account</Heading>
                  <Text color="fg.muted">
                    Already have an account? <Link href="/login">Sign In</Link>
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
                    {messages.show ? <AlertPopUp {...messages.alertMessage} /> : <></>}
                    <FormControl isInvalid={!!(touched.name && errors.name)}>
                        <FormLabel htmlFor="name">Name</FormLabel>
                        <Input variant='outline' placeholder='Name' {...getFieldProps('name')} />
                        <ErrorMessage name='name' />
                    </FormControl>

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

                    <FormControl isInvalid={!!(touched.password_confirmation && errors.password_confirmation)}>
                        <FormLabel htmlFor="password">Password</FormLabel>
                        <Input id="password_confirmation" type="password" placeholder="********" {...getFieldProps('password_confirmation')} />
                        <ErrorMessage name='password_confirmation' />
                    </FormControl>
                  </Stack>
                  <HStack justify="space-between">
                    <Checkbox defaultChecked>Remember me</Checkbox>
                    <Button variant="text" size="sm">
                      Forgot password?
                    </Button>
                  </HStack>
                  <Stack spacing="6">
                    <Button type='submit' isLoading={submitting} loadingText="Signing Up">
                      Sign up
                    </Button>
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

export default SignUp;
