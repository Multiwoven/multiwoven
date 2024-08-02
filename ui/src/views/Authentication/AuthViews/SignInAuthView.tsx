import AuthCard from '../AuthCard';
import { Form, Formik } from 'formik';
import { Button, Checkbox, HStack, Heading, Stack, Text } from '@chakra-ui/react';
import { FormField, PasswordField } from '@/components/Fields';
import { Link } from 'react-router-dom';
import { SignInAuthViewProps, SignInSchema } from '../types';

export const SignInAuthView = ({
  brandName,
  logoUrl,
  handleSubmit,
  submitting,
}: SignInAuthViewProps) => (
  <>
    <AuthCard logoUrl={logoUrl} brandName={brandName}>
      <Formik
        initialValues={{
          email: '',
          password: '',
        }}
        onSubmit={(values) => handleSubmit(values)}
        validationSchema={SignInSchema}
      >
        {({ getFieldProps, touched, errors }) => (
          <Form>
            <Stack spacing='8px' textAlign='center' mb='32px'>
              <Heading size='xs' fontWeight='semibold'>
                {"Let's activate your data"}
              </Heading>
              <Text size='sm' color='black.200'>
                {`Sign In to your ${brandName} account`}
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
                <PasswordField
                  placeholder='Enter password'
                  name='password'
                  type='password'
                  getFieldProps={getFieldProps}
                  touched={touched}
                  errors={errors}
                />
                <HStack justify='space-between'>
                  <Checkbox
                    defaultChecked
                    _checked={{
                      '& .chakra-checkbox__control': {
                        background: 'brand.400',
                        borderColor: 'brand.400',
                      },
                      '& .chakra-checkbox__control:hover': {
                        background: 'brand.400',
                        borderColor: 'brand.400',
                      },
                    }}
                    iconSize='12px'
                    size='sm'
                  >
                    <Text size='xs' fontWeight='medium'>
                      Stay signed in
                    </Text>
                  </Checkbox>
                  <Text size='xs' color='brand.400' fontWeight='semibold'>
                    Forgot Password?
                  </Text>
                </HStack>
              </Stack>
              <Stack spacing='6'>
                <Button
                  type='submit'
                  isLoading={submitting}
                  loadingText='Signing In'
                  variant='solid'
                  width='full'
                >
                  Sign In
                </Button>
              </Stack>
              <HStack spacing={1} justify='center'>
                <Text color='black.500' size='xs' fontWeight='medium'>
                  {"Don't have an account?"}{' '}
                </Text>
                <Link to='/sign-up'>
                  <Text color='brand.400' size='xs' fontWeight='semibold'>
                    Sign Up
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
