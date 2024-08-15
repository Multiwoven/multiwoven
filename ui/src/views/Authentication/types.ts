import { ReactNode } from 'react';

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
  privacyPolicyUrl: string;
  termsOfServiceUrl: string;
  isCompanyNameDisabled?: boolean;
  isEmailDisabled?: boolean;
};

export type ResetPasswordFormPayload = {
  password: string;
  password_confirmation: string;
};

export type ForgotPasswordFormPayload = {
  email: string;
};

type ChangePasswordProps<T> = {
  brandName: string;
  logoUrl: string;
  handleSubmit: (values: T) => void;
  submitting: boolean;
};

export type ForgotPasswordAuthViewProps = ChangePasswordProps<ForgotPasswordFormPayload>;
export type ResetPasswordAuthViewProps = ChangePasswordProps<ResetPasswordFormPayload>;
