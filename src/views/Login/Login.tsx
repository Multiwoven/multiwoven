import { Formik, Form } from 'formik';
import * as Yup from 'yup';
import { Link as RouterLink } from 'react-router-dom';
import {
    Box, Button, FormControl, FormLabel, FormErrorMessage, Input,
    VStack, Image, Heading, Text, Link, Container, Flex, Spacer, Checkbox, background
} from '@chakra-ui/react';
import MultiwovenLogo from '../../assets/images/multiwoven-logo.png';

// Yup validation schema
const SignUpSchema = Yup.object().shape({
    email: Yup.string()
        .email('Invalid email address')
        .required('Email is required'),
    password: Yup.string()
        .min(8, 'Password must be at least 8 characters')
        .required('Password is required'),
});

function Login() {
    return (

        <Container display='flex' flexDir='column' justifyContent='center' maxW='650' minH='100vh' className='flex flex-col align-center justify-center'>
            <div className='top_side_back'></div>
            <div className='bottom_side_back'></div>
            <Box width='100%' className="flex min-h-full flex-1 flex-col align-center justify-center py-12 sm:px-6 lg:px-8">
                <Box display='flex' justifyContent='center' className="sm:mx-auto sm:w-full sm:max-w-sm">
                    <Image
                        maxW="360px"
                        w="95%"
                        src={MultiwovenLogo}
                        alt="Multiwoven"
                    />

                </Box>

                <Box mt="10" className="sm:mx-auto sm:w-full sm:max-w-[480px]">
                    <Box bg="white" border='1px' borderColor="#E2E8F0" px="24" py="9" rounded="lg" className="sm:px-12">
                        <Heading fontSize='40px' as="h2" mt="0" mb='10' fontWeight="normal" textAlign="center" >
                            Log in to your account
                        </Heading>
                        <Formik
                            initialValues={{ email: '', password: '' }}
                            validationSchema={SignUpSchema}
                            onSubmit={(values, actions) => {
                                console.log(values);
                                actions.setSubmitting(false);
                            }}
                        >
                            {({ getFieldProps, errors, touched }) => (
                                <Form>
                                    <FormControl mb='24px' id="email" isInvalid={errors.email && touched.email}>
                                        <Input variant='outline' placeholder='Email' {...getFieldProps('email')} />
                                        {/* <FormErrorMessage>{errors.email}</FormErrorMessage> */}
                                    </FormControl>

                                    <FormControl mb='24px' id="password" isInvalid={errors.password && touched.password}>
                                        <Input type="password" placeholder='Password' {...getFieldProps('password')} />
                                        {/* <FormErrorMessage>{errors.password}</FormErrorMessage> */}
                                    </FormControl>

                                    <Button type="submit" background="#E63D2D" color='white' width="full" _hover={{ background: "#E63D2D" }}>
                                        Login
                                    </Button>
                                </Form>
                            )}
                        </Formik>
                        <Box width='100%' className="flex min-h-full flex-1 flex-col align-center justify-center py-12 sm:px-6 lg:px-8">
                            <Flex paddingBottom='5' borderBottom='1px' borderColor='#CCBBDD5E'>
                                <Text mt="4" textAlign="left" fontSize="sm" color="black">
                                    <Checkbox size='md' colorScheme='blue'>
                                        Remember me
                                    </Checkbox>
                                </Text>
                                <Spacer />
                                <Text mt="4" textAlign="right" fontSize="sm" color="gray.500">
                                    <Link fontWeight="500" as={RouterLink} to="/login" color="#E63D2D" _hover={{ color: '#E63D2D' }}>
                                        Forgot password
                                    </Link>
                                </Text>
                            </Flex>
                            <Text display='flex' mt="5" textAlign="left" fontSize="sm" color="gray.500">
                                Don't have an account?
                                <Link ml='1' as={RouterLink} to="/login" color="#E63D2D" _hover={{ color: '#E63D2D' }}>
                                    Sign Up
                                </Link>
                            </Text>
                        </Box>
                    </Box>


                </Box>
            </Box>

        </Container>

    )
}

export default Login;
