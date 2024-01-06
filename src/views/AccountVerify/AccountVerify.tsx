import { Formik, Form, ErrorMessage } from 'formik';
import * as Yup from 'yup';
import { Link, useNavigate } from 'react-router-dom';
import {
    Box, Button, FormControl, Image, Heading, Text, Input, Container, Stack, HStack, Checkbox, FormLabel, Divider,
} from '@chakra-ui/react';
import MultiwovenIcon from '../../assets/images/icon.png';
import { axiosInstance as axios } from "../../services/axios";
import AlertPopUp, { alertMessage } from '@/components/Alerts/Alerts';
import { useState } from 'react';

// Yup validation schema
const AccountVerifySchema = Yup.object().shape({
    code: Yup.string()
        .required('Code is required'),
});

const AccountVerify = () => {
    let message = alertMessage;
    const [messages, setMessages] = useState({
      show: false,
      alertMessage: message
    });
  
    const [submitting, setSubmitting] = useState(false);

    const navigate = useNavigate();
    const handleSubmit = async (values: any) => {
        setSubmitting(true);
        let data = {
            "email":sessionStorage.getItem("userEmail"),
            "confirmation_code":values.code
        }
        await axios.post('/verify_code', data)
        .then(response => {
            if (response.status === 200) {
                setSubmitting(false);
                navigate('/login')
            }
        }).catch(error => {
            setSubmitting(false);
            message = {
                status: 'error',
                description: [error.response.data.error.message]
              };
              setMessages({ show: true, alertMessage: message });
            console.error('Verification error:', error);
        })
    }
    return (

        // <Container display='flex' flexDir='column' justifyContent='center' maxW='650' minH='100vh' className='flex flex-col align-center justify-center'>
        //     <div className='top_side_back'></div>
        //     <div className='bottom_side_back'></div>
        //     <Box width='100%' className="flex min-h-full flex-1 flex-col align-center justify-center py-12 sm:px-6 lg:px-8">
        //         <Box display='flex' justifyContent='center' className="sm:mx-auto sm:w-full sm:max-w-sm">
        //             <Image
        //                 maxW="300px"
        //                 w="95%"
        //                 src={MultiwovenLogo}
        //                 alt="Multiwoven"
        //             />

        //         </Box>

        //         <Box mt="14" className="sm:mx-auto sm:w-full sm:max-w-[480px]">
        //             <Box bg="white" border='1px' borderColor="border" px="24" py="12" rounded="lg" className="sm:px-12">
        //                 <Heading fontSize='40px' as="h2" mt="0" mb='2' fontWeight="normal" textAlign="center" >
        //                     Verify Your account
        //                 </Heading>
        //                 <Text display='flex' mt="1" mb='7' justifyContent="center" fontSize="md" color="gray.500">
        //                     Please check your Email for the verification code
        //                 </Text>
        //                 <Formik
        //                     initialValues={{ code: '' }}
        //                     validationSchema={SignUpSchema}
        //                     onSubmit={(values) => handleSubmit(values)}
        //                 >
        //                     {({ getFieldProps, errors, touched }) => (
        //                         <Form>
        //                             <FormControl mb='24px' id="code" data-invalid={errors.code && touched.code}>
        //                                 <Input variant='outline' placeholder='Enter the verification code' {...getFieldProps('code')} />
        //                                 {/* <FormErrorMessage>{errors.code}</FormErrorMessage> */}
        //                             </FormControl>


        //                             <Button type="submit" background="secondary" color='white' width="full" _hover={{ background: "secondary" }}>
        //                                 Submit
        //                             </Button>
        //                         </Form>
        //                     )}
        //                 </Formik>

        //             </Box>


        //         </Box>
        //     </Box>

        // </Container>

        <Formik
            initialValues={{ code: '' }}
            onSubmit={(values) => handleSubmit(values)}
            validationSchema={AccountVerifySchema}
            >
            {({ getFieldProps, touched, errors }) => (
                <Form>
                <Container maxW="lg" py={{ base: '12', md: '24' }} px={{ base: '0', sm: '8' }}>
                    <Stack spacing="8">
                    <Stack spacing="6" alignItems={'center'}>
                        <img src={MultiwovenIcon} width={55} />
                        <Stack spacing={{ base: '2', md: '3' }} textAlign="center">
                            <Heading size={{ base: 'xs', md: 'sm' }}>Verify your account</Heading>
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
                                <FormControl isInvalid={!!(touched.code && errors.code)}>
                                    <FormLabel htmlFor="code">Verification Code</FormLabel>
                                    <Input id="code" type="code" {...getFieldProps('code')} />
                                    <ErrorMessage name='code' />
                                </FormControl>
                                <Button type='submit' isLoading={submitting} loadingText="Verifying">
                                    Verify
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

export default AccountVerify;
