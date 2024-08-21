import * as Yup from 'yup';

const email = Yup.string()
  .email('Please enter a valid email address')
  .required('Email is required');

const password = Yup.string()
  .min(8, 'Password must be at least 8 characters')
  .max(128, 'Password cannot be more than 128 characters')
  .matches(/[A-Z]/, 'Password must contain at least one uppercase letter')
  .matches(/[a-z]/, 'Password must contain at least one lowercase letter')
  .matches(/\d/, 'Password must contain at least one digit')
  .matches(/[@$!%*?&]/, 'Password must contain at least one special character')
  .required('Password is required');

const password_confirmation = Yup.string()
  .oneOf([Yup.ref('password'), ''], 'Passwords must match')
  .required('Confirm Password is required');

export const SignInSchema = Yup.object().shape({
  email: email,
  password: Yup.string()
    .min(8, 'Password must be at least 8 characters')
    .required('Password is required'),
});

export const SignUpSchema = Yup.object().shape({
  company_name: Yup.string().required('Company name is required'),
  name: Yup.string().required('Name is required'),
  email: email,
  password: password,
  password_confirmation: password_confirmation,
});

export const ForgotPasswordSchema = Yup.object().shape({
  email: email,
});

export const ResetPasswordSchema = Yup.object().shape({
  password: password,
  password_confirmation: password_confirmation,
});
