import { Formik, Form } from 'formik';
import * as Yup from 'yup';
import { Link as RouterLink } from 'react-router-dom';
import { 
    Box, Button, FormControl, FormLabel, FormErrorMessage, Input, 
    VStack, Image, Heading, Text, Link
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
    confirmPassword: Yup.string()
        .oneOf([Yup.ref('password'), null], 'Passwords must match')
        .required('Confirm Password is required'),
});

function SignUp() {
    return (
        <Box className="flex min-h-full flex-1 flex-col justify-center py-12 sm:px-6 lg:px-8">
            <Box className="sm:mx-auto sm:w-full sm:max-w-sm">
                <Image
                    mx="auto"
                    h="10"
                    w="auto"
                    src={MultiwovenLogo}
                    alt="Multiwoven"
                />
                <Heading as="h2" mt="10" textAlign="center" size="xl">
                    Sign up for an account
                </Heading>
            </Box>

            <Box mt="10" className="sm:mx-auto sm:w-full sm:max-w-[480px]">
                <Box bg="white" px="6" py="12" shadow="sm" rounded="lg" className="sm:px-12">
                    <Formik
                        initialValues={{ email: '', password: '', confirmPassword: '' }}
                        validationSchema={SignUpSchema}
                        onSubmit={(values, actions) => {
                            console.log(values);
                            actions.setSubmitting(false);
                        }}
                    >
                        {({ getFieldProps, errors, touched }) => (
                            <Form>
                                <FormControl id="email" isInvalid={errors.email && touched.email}>
                                    <FormLabel>Email address</FormLabel>
                                    <Input type="email" {...getFieldProps('email')} />
                                    <FormErrorMessage>{errors.email}</FormErrorMessage>
                                </FormControl>

                                <FormControl id="password" isInvalid={errors.password && touched.password}>
                                    <FormLabel>Password</FormLabel>
                                    <Input type="password" {...getFieldProps('password')} />
                                    <FormErrorMessage>{errors.password}</FormErrorMessage>
                                </FormControl>

                                <FormControl id="confirmPassword" isInvalid={errors.confirmPassword && touched.confirmPassword}>
                                    <FormLabel>Confirm Password</FormLabel>
                                    <Input type="password" {...getFieldProps('confirmPassword')} />
                                    <FormErrorMessage>{errors.confirmPassword}</FormErrorMessage>
                                </FormControl>

                                <Button type="submit" colorScheme="orange" width="full">
                                    Sign Up!
                                </Button>
                            </Form>
                        )}
                    </Formik>
                </Box>

                <Text mt="10" textAlign="center" fontSize="sm" color="gray.500">
                    Already have an account?{' '}
                    <Link as={RouterLink} to="/login" color="orange.600" _hover={{ color: 'orange.500' }}>
                        Sign In
                    </Link>
                </Text>
            </Box>
        </Box>
    )
}

export default SignUp;
