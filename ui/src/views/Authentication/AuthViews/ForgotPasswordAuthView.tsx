import AuthCard from '../AuthCard';
import { Form, Formik } from 'formik';
import { Button, HStack, Heading, Stack, Text } from '@chakra-ui/react';
import { FormField } from '@/components/Fields';
import { Link } from 'react-router-dom';
import { ForgotPasswordAuthViewProps } from '../types';
import { ForgotPasswordSchema } from '@/constants/schemas';

export const ForgotPasswordAuthView = ({
  brandName,
  logoUrl,
  handleSubmit,
  submitting,
}: ForgotPasswordAuthViewProps) => {
  return (
    <>
      <AuthCard logoUrl={logoUrl} brandName={brandName}>
        <Formik
          initialValues={{
            email: '',
          }}
          onSubmit={handleSubmit}
          validationSchema={ForgotPasswordSchema}
        >
          {({ getFieldProps, touched, errors }) => (
            <Form>
              <Stack spacing='8px' textAlign='center' mb='32px'>
                <Heading size='xs' fontWeight='semibold'>
                  Reset your password
                </Heading>
                <Text size='sm' color='black.200'>
                  Enter your email address and we will send you instructions to reset your password.
                </Text>
              </Stack>
              <Stack spacing='6'>
                <Stack spacing='3'>
                  <FormField
                    placeholder='Enter email'
                    name='email'
                    type='text'
                    getFieldProps={getFieldProps}
                    touched={touched}
                    errors={errors}
                  />
                </Stack>
                <Stack spacing='6'>
                  <Button
                    type='submit'
                    isLoading={submitting}
                    loadingText='Submitting'
                    variant='solid'
                    width='full'
                  >
                    Continue
                  </Button>
                </Stack>
                <HStack spacing={1} justify='center'>
                  <Link to='/sign-in'>
                    <Text color='brand.400' size='xs' fontWeight='semibold'>
                      Back to {brandName}
                    </Text>
                  </Link>
                </HStack>
              </Stack>
            </Form>
          )}
        </Formik>
      </AuthCard>
    </>
  );
};
