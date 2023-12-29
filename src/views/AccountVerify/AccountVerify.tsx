import { Formik, Form } from 'formik';
import * as Yup from 'yup';
import { Link as RouterLink, useNavigate } from 'react-router-dom';
import {
    Box, Button, FormControl, FormLabel, FormErrorMessage, Input,
    VStack, Image, Heading, Text, Link, Container, Flex, Spacer, Checkbox, background
} from '@chakra-ui/react';
import MultiwovenLogo from '../../assets/images/multiwoven-logo.png';
import { axiosInstance as axios } from "../../services/axios";
import Cookies from 'js-cookie';
// Yup validation schema
const SignUpSchema = Yup.object().shape({
    email: Yup.string()
        .email('Invalid email address')
        .required('Email is required'),
    password: Yup.string()
        .required('Password is required'),
});

const AccountVerify = () => {
    const navigate = useNavigate();
    const handleSubmit = async (values: any) => {
        let data = JSON.stringify(values)
        await axios.post('/login', data).then(response => {
            let token = response?.data?.token;
            Cookies.set('authToken', token);
            navigate('/')
        }).catch(error => {
            console.error('Login error:', error);
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
                        <Heading fontSize='40px' as="h2" mt="0" mb='2' fontWeight="normal" textAlign="center" >
                            Verify Your account
                        </Heading>
                        <Text display='flex' mt="1" mb='7' justifyContent="center" fontSize="md" color="gray.500">
                            Please check your email for the verification code
                        </Text>
                        <Formik
                            initialValues={{ email: '', password: '' }}
                            validationSchema={SignUpSchema}
                            onSubmit={(values) => handleSubmit(values)}
                        >
                            {({ getFieldProps, errors, touched }) => (
                                <Form>
                                    <FormControl mb='24px' id="email" isInvalid={errors.email && touched.email}>
                                        <Input variant='outline' placeholder='Enter the verification code' {...getFieldProps('email')} />
                                        {/* <FormErrorMessage>{errors.email}</FormErrorMessage> */}
                                    </FormControl>


                                    <Button type="submit" background="#731447" color='white' width="full" _hover={{ background: "#731447" }}>
                                        Submit
                                    </Button>
                                </Form>
                            )}
                        </Formik>

                    </Box>


                </Box>
            </Box>

        </Container>

    )
}

export default AccountVerify;
