import { Formik, Form } from 'formik';
import * as Yup from 'yup';
import { Link as RouterLink } from 'react-router-dom';
import {
    Box, Button, FormControl, Input, Image, Heading, Text, Link, Container
} from '@chakra-ui/react';
import MultiwovenLogo from '../../assets/images/multiwoven-logo.png';
import { axiosInstance as axios } from "../../services/axios";

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
    password_confirmation: Yup.string()
        .oneOf([Yup.ref('password'), ''], 'Passwords must match')
        .required('Confirm Password is required'),
});



const SignUp = () => {
    const handleSubmit = async (values: any) => {
        let data = JSON.stringify(values)
        await axios.post('/signup', data).then(response => {
            console.log("respone", response)
        }).catch(error => {
            console.error('signUp error:', error);
        })
    }
    return (

        <Container display='flex' flexDir='column' justifyContent='center' maxW='650' minH='100vh' className='flex flex-col align-center justify-center'>
            <div className='top_side_back'></div>
            <div className='bottom_side_back'></div>
            <Box width='100%' className="flex min-h-full flex-1 flex-col align-center justify-center py-12 sm:px-6 lg:px-8">
                <Box display='flex' justifyContent='center' className="sm:mx-auto sm:w-full sm:max-w-sm">
                    <Image
                        maxW="300px"
                        w="95%"
                        src={MultiwovenLogo}
                        alt="Multiwoven"
                    />

                </Box>

                <Box mt="10" className="sm:mx-auto sm:w-full sm:max-w-[480px]">
                    <Box bg="white" border='1px' borderColor="#E2E8F0" px="24" py="9" rounded="lg" className="sm:px-12">
                        <Heading fontSize='40px' as="h2" mt="0" mb='10' fontWeight="normal" textAlign="center" >
                            Create an account
                        </Heading>
                        <Formik
                            initialValues={{ email: '', password: '', password_confirmation: '' }}
                            validationSchema={SignUpSchema}
                            onSubmit={(values) => handleSubmit(values)}

                        >
                            {({ getFieldProps, errors, touched }) => (
                                <Form>
                                    <FormControl mb='24px' id="name">
                                        <Input variant='outline' placeholder='Name' {...getFieldProps('name')} />
                                    </FormControl>

                                    <FormControl mb='24px' id="email" isInvalid={touched.email}>
                                        <Input variant='outline' placeholder='Email' {...getFieldProps('email')} />
                                        {/* <FormErrorMessage>{errors.email}</FormErrorMessage> */}
                                    </FormControl>

                                    <FormControl mb='24px' id="password" isInvalid={touched.password}>
                                        <Input type="password" placeholder='Password' {...getFieldProps('password')} />
                                        {/* <FormErrorMessage>{errors.password}</FormErrorMessage> */}
                                    </FormControl>

                                    <FormControl mb='8px' id="password_confirmation" isInvalid={touched.password_confirmation}>
                                        <Input type="password" placeholder='Confirm Password' {...getFieldProps('password_confirmation')} />
                                        {/* <FormErrorMessage>{errors.confirmPassword}</FormErrorMessage> */}
                                    </FormControl>
                                    <Text mt="0" mb='24px' textAlign="left" fontSize="sm" color="gray.500">
                                        At least 8 characters long
                                    </Text>

                                    <Button type="submit" background="#731447DD" color='white' width="full" _hover={{ background: '#731447DD' }}>
                                        Create Account
                                    </Button>
                                </Form>
                            )}
                        </Formik>
                    </Box>

                    <Text mt="10" textAlign="center" fontSize="sm" color="gray.500">
                        Already have an account?{' '}
                        <Link as={RouterLink} to="/login" color="#5383EC" _hover={{ color: '#5383EC' }}>
                            Sign In
                        </Link>
                    </Text>
                </Box>
            </Box>

        </Container>

    )
}

export default SignUp;
