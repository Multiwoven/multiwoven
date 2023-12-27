import { Formik, Form } from 'formik';
import * as Yup from 'yup';
import { Link as RouterLink } from 'react-router-dom';
import {
    Box, Button, FormControl, FormLabel, FormErrorMessage, Input,
    VStack, Image, Heading, Text, Link, Container, Flex
} from '@chakra-ui/react';
import MultiwovenLogo from '../../assets/images/multiwoven-logo.png';

// Yup validation schema
const SignUpSchema = Yup.object().shape({
    name: Yup.string()
        .required('Name is required'),
    email: Yup.string()
        .email('Invalid email address')
        .required('Email is required'),
    password: Yup.string()
        .min(8, 'Password must be at least 8 characters')
        .required('Password is required'),
    confirmPassword: Yup.string()
        .oneOf([Yup.ref('password'), null], 'Passwords must match')
        .required('Confirm Password is required'),
});

function SignUp() {
    return (

        <Container display='flex' flexDir='column' justifyContent='center' maxW='700' minH='100vh' className='flex flex-col align-center justify-center'>
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
                    <Box bg="white" border='1px' borderColor="#E2E8F0" px="20" py="9" rounded="lg" className="sm:px-12">
                        <Heading fontSize='48px' as="h2" mt="0" mb='10' fontWeight="normal" textAlign="center" >
                            Create an account
                        </Heading>
                        <Formik
                            initialValues={{ name: '', email: '', password: '', confirmPassword: '' }}
                            validationSchema={SignUpSchema}
                            onSubmit={(values, actions) => {
                                console.log(values);
                                actions.setSubmitting(false);
                            }}
                        >
                            {({ getFieldProps, errors, touched }) => (
                                <Form>
                                    <FormControl mb='24px' id="email" isInvalid={errors.name && touched.name}>
                                        <Input variant='outline' placeholder='Name' {...getFieldProps('name')} />
                                        {/* <FormErrorMessage>{errors.email}</FormErrorMessage> */}
                                    </FormControl>

                                    <FormControl mb='24px' id="email" isInvalid={errors.email && touched.email}>
                                        <Input variant='outline' placeholder='Email' {...getFieldProps('email')} />
                                        {/* <FormErrorMessage>{errors.email}</FormErrorMessage> */}
                                    </FormControl>

                                    <FormControl mb='24px' id="password" isInvalid={errors.password && touched.password}>
                                        <Input type="password" placeholder='Password' {...getFieldProps('password')} />
                                        {/* <FormErrorMessage>{errors.password}</FormErrorMessage> */}
                                    </FormControl>

                                    <FormControl mb='8px' id="confirmPassword" isInvalid={errors.confirmPassword && touched.confirmPassword}>
                                        <Input type="password" placeholder='Confirm Password' {...getFieldProps('confirmPassword')} />
                                        {/* <FormErrorMessage>{errors.confirmPassword}</FormErrorMessage> */}
                                    </FormControl>
                                    <Text mt="0" mb='24px' textAlign="left" fontSize="sm" color="gray.500">
                                        At least 8 characters long
                                    </Text>

                                    <Button type="submit" background="#E63D2D" color='white' width="full">
                                        Create Account
                                    </Button>
                                </Form>
                            )}
                        </Formik>
                    </Box>

                    <Text mt="10" textAlign="center" fontSize="sm" color="gray.500">
                        Already have an account?{' '}
                        <Link as={RouterLink} to="/login" color="#E63D2D" _hover={{ color: '#E63D2D' }}>
                            Sign In
                        </Link>
                    </Text>
                </Box>
            </Box>

        </Container>

    )
}

export default SignUp;
