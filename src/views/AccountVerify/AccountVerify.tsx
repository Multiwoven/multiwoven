import { Formik, Form, ErrorMessage } from 'formik';
import * as Yup from 'yup';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Button,
  FormControl,
  Heading,
  Input,
  Container,
  Stack,
  HStack,
  FormLabel,
} from '@chakra-ui/react';
import MultiwovenIcon from '@/assets/images/icon.png';
import { useState } from 'react';
import { accountVerify } from '@/services/common';

const AccountVerifySchema = Yup.object().shape({
  code: Yup.string().required('Code is required'),
});

const AccountVerify = (): JSX.Element => {
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (values: any) => {
    setSubmitting(true);
    const data = {
      email: sessionStorage.getItem('userEmail'),
      confirmation_code: values.code,
    };
    const result = await accountVerify(data);
    if (result.success) {
      setSubmitting(false);
      navigate('/login');
    } else {
      setSubmitting(false);
    }
  };
  return (
    <Formik
      initialValues={{ code: '' }}
      onSubmit={(values) => handleSubmit(values)}
      validationSchema={AccountVerifySchema}
    >
      {({ getFieldProps, touched, errors }) => (
        <Form>
          <Container maxW='lg' py={{ base: '12', md: '24' }} px={{ base: '0', sm: '8' }}>
            <Stack spacing='8'>
              <Stack spacing='6' alignItems={'center'}>
                <img src={MultiwovenIcon} width={55} />
                <Stack spacing={{ base: '2', md: '3' }} textAlign='center'>
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
                <Stack spacing='6'>
                  <Stack spacing='5'>
                    <FormControl isInvalid={!!(touched.code && errors.code)}>
                      <FormLabel htmlFor='code'>Verification Code</FormLabel>
                      <Input id='code' type='code' {...getFieldProps('code')} />
                      <ErrorMessage name='code' />
                    </FormControl>
                    <Button type='submit' isLoading={submitting} loadingText='Verifying'>
                      Verify
                    </Button>
                  </Stack>
                  <HStack justify='space-between'>
                    <Button variant='text' size='sm'>
                      Resend Code
                    </Button>
                  </HStack>
                </Stack>
              </Box>
            </Stack>
          </Container>
        </Form>
      )}
    </Formik>
  );
};

export default AccountVerify;
