import { Form, Formik } from 'formik';
import { Button, HStack, Stack, Text } from '@chakra-ui/react';
import { FormField, PasswordField } from '@/components/Fields';
import { Link } from 'react-router-dom';
import { SignUpAuthViewProps } from '../types';
import { SignUpSchema } from '@/constants/schemas';

export const SignUpAuthView = ({
  handleSubmit,
  submitting,
  initialValues,
  // privacyPolicyUrl,
  // termsOfServiceUrl,
  isCompanyNameDisabled,
  isEmailDisabled,
}: SignUpAuthViewProps) => (
  <>
    <Formik
      initialValues={{
        company_name: initialValues ? initialValues.company_name : '',
        name: '',
        email: initialValues ? initialValues.email : '',
        password: '',
        password_confirmation: '',
      }}
      onSubmit={handleSubmit}
      validationSchema={SignUpSchema}
    >
      {({ getFieldProps, touched, errors }) => (
        <Form>
          <Stack spacing='20px'>
            <Stack spacing='16px'>
              <FormField
                placeholder='Enter company name'
                name='company_name'
                type='text'
                getFieldProps={getFieldProps}
                touched={touched}
                errors={errors}
                tooltipText='Company Names are unique across the platform'
                hasTooltip
                isDisabled={isCompanyNameDisabled}
              />
              <FormField
                placeholder='Enter name'
                name='name'
                type='text'
                getFieldProps={getFieldProps}
                touched={touched}
                errors={errors}
              />
              <FormField
                placeholder='Enter email'
                name='email'
                type='text'
                getFieldProps={getFieldProps}
                touched={touched}
                errors={errors}
                tooltipText='Please use an email linked to your company'
                hasTooltip
                isDisabled={isEmailDisabled}
              />
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
              {/*<HStack spacing={1}>
                <Text color='black.200' size='xs' fontWeight='regular'>
                  By creating an account, I agree to the{' '}
                </Text>
                <Link to={termsOfServiceUrl} target='_blank'>
                  <Text color='brand.400' size='xs' fontWeight='medium'>
                    Terms
                  </Text>
                </Link>
                <Text color='black.200' size='xs' fontWeight='regular'>
                  and
                </Text>
                <Link to={privacyPolicyUrl} target='_blank'>
                  <Text color='brand.400' size='xs' fontWeight='medium'>
                    Privacy Policy
                  </Text>
                </Link>
              </HStack>*/}
            </Stack>
            <Stack spacing='6'>
              <Button
                type='submit'
                isLoading={submitting}
                loadingText='Creating Account'
                variant='solid'
                width='full'
              >
                Create Account
              </Button>
              <HStack spacing={1} justify='center'>
                <Text color='black.500' size='xs' fontWeight='medium'>
                  Do you have an account?{' '}
                </Text>
                <Link to='/sign-in'>
                  <Text color='brand.400' size='xs' fontWeight='semibold'>
                    Sign In
                  </Text>
                </Link>
              </HStack>
            </Stack>
          </Stack>
        </Form>
      )}
    </Formik>
  </>
);
