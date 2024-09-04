import { ReactNode } from 'react';

type DefaultAuthViewProps = {
  brandName: string;
  logoUrl: string;
};

type Email = {
  email: string;
};

type Password = {
  password: string;
  password_confirmation: string;
};

export type AuthCardProps = {
  children: ReactNode;
} & DefaultAuthViewProps;

export type SignInAuthViewProps = {
  handleSubmit: (values: any) => void;
  submitting: boolean;
} & DefaultAuthViewProps;

type InitialValues = {
  company_name: string;
  name: string;
} & Email &
  Password;

export type SignUpAuthViewProps = {
  handleSubmit: (values: any) => void;
  submitting: boolean;
  initialValues?: InitialValues;
  privacyPolicyUrl: string;
  termsOfServiceUrl: string;
  isCompanyNameDisabled?: boolean;
  isEmailDisabled?: boolean;
} & DefaultAuthViewProps;

export type ResetPasswordFormPayload = Password;

export type ForgotPasswordFormPayload = Email;

type ChangePasswordProps<T> = {
  handleSubmit: (values: T) => void;
  submitting: boolean;
} & DefaultAuthViewProps;

export type ForgotPasswordAuthViewProps = ChangePasswordProps<ForgotPasswordFormPayload>;
export type ResetPasswordAuthViewProps = ChangePasswordProps<ResetPasswordFormPayload>;

export type VerificationAuthViewProps = {
  handleEmailResend: (email: string) => void;
  submitting: boolean;
} & DefaultAuthViewProps &
  Email;

export type VerifyUserFailedAuthViewProps = {
  resendEmail: () => void;
} & DefaultAuthViewProps;

export type VerifyUserSuccessAuthViewProps = DefaultAuthViewProps;
