import AuthCard from '../AuthCard';
import { Form, Formik } from 'formik';
import { Button, HStack, Heading, Stack, Text } from '@chakra-ui/react';
import { PasswordField } from '@/components/Fields';
import { Link } from 'react-router-dom';
import { ResetPasswordAuthViewProps } from '../types';
import { ResetPasswordSchema } from '@/constants/schemas';

export const ResetPasswordAuthView = ({
  brandName,
  logoUrl,
  handleSubmit,
  submitting,
}: ResetPasswordAuthViewProps) => {
  return (
    <>
      <AuthCard logoUrl={logoUrl} brandName={brandName}>
        <Formik
          initialValues={{
            password: '',
            password_confirmation: '',
          }}
          onSubmit={handleSubmit}
          validationSchema={ResetPasswordSchema}
        >
          {({ getFieldProps, touched, errors }) => (
            <Form>
              <Stack spacing='8px' textAlign='center' mb='32px'>
                <Heading size='xs' fontWeight='semibold'>
                  {'Reset your password'}
                </Heading>
                <Text size='sm' color='black.200'>
                  {`Enter a new password below to change your password`}
                </Text>
              </Stack>
              <Stack spacing='6'>
                <Stack spacing='3'>
                  <PasswordField
                    id='password'
                    placeholder='Choose password'
                    name='password'
                    type='password'
                    getFieldProps={getFieldProps}
                    touched={touched}
                    errors={errors}
                    helperText='Password must be 8-128 characters long and include at least one uppercase letter, one lowercase letter, one digit, and one special character.'
                  />
                  <PasswordField
                    id='password_confirmation'
                    placeholder='Confirm password'
                    name='password_confirmation'
                    type='password'
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
                    Reset Password
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
