import { ReactNode } from 'react';
import * as Yup from 'yup';

export const SignInSchema = Yup.object().shape({
  email: Yup.string().email('Please enter a valid email address').required('Email is required'),
  password: Yup.string()
    .min(8, 'Password must be at least 8 characters')
    .required('Password is required'),
});

export const SignUpSchema = Yup.object().shape({
  company_name: Yup.string().required('Company name is required'),
  name: Yup.string().required('Name is required'),
  email: Yup.string().email('Invalid email address').required('Email is required'),
  password: Yup.string()
    .min(8, 'Password must be at least 8 characters')
    .max(128, 'Password cannot be more than 128 characters')
    .matches(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .matches(/[a-z]/, 'Password must contain at least one lowercase letter')
    .matches(/\d/, 'Password must contain at least one digit')
    .matches(/[@$!%*?&]/, 'Password must contain at least one special character')
    .required('Password is required'),
  password_confirmation: Yup.string()
    .oneOf([Yup.ref('password'), ''], 'Passwords must match')
    .required('Confirm Password is required'),
});

export type AuthCardProps = {
  children: ReactNode;
  brandName: string;
  logoUrl: string;
};

export type SignInAuthViewProps = {
  brandName: string;
  logoUrl: string;
  handleSubmit: (values: any) => void;
  submitting: boolean;
};

type InitialValues = {
  company_name: string;
  name: string;
  email: string;
  password: string;
  password_confirmation: string;
};

export type SignUpAuthViewProps = {
  brandName: string;
  logoUrl: string;
  handleSubmit: (values: any) => void;
  submitting: boolean;
  initialValues?: InitialValues;
};
