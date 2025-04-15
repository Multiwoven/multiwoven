import { ErrorResponse, multiwovenFetch } from './common';
import { buildUrlWithParams } from './utils';

export type SignUpPayload = {
  email: string;
  name: string;
  company_name: string;
  password: string;
  password_confirmation: string;
};

export type SignInPayload = {
  email: string;
  password: string;
};

export type AuthErrorResponse = {
  status: number;
  title: string;
  detail: string;
};

export type SignInResponse = {
  type: string;
  id: string;
  attributes: {
    token: string;
  };
  errors?: AuthErrorResponse[];
};

export type AuthResponse = {
  type: string;
  id: string;
  attributes: {
    token: string;
  };
  errors?: AuthErrorResponse[];
};

export type ApiResponse<T> = {
  data?: T;
  status: number;
  errors?: ErrorResponse[];
};

export type ForgotPasswordPayload = {
  email: string;
};

export type MessageResponse = {
  type: string;
  id: number;
  attributes: {
    message: string;
  };
};

export type ResetPasswordPayload = {
  reset_password_token: string;
  password: string;
  password_confirmation: string;
};

export type SignUpResponse = {
  type: string;
  id: string;
  attributes: {
    created_at: string;
    email: string;
    name: string;
  };
  errors?: AuthErrorResponse[];
};

export const signUp = async (payload: SignUpPayload) =>
  multiwovenFetch<SignUpPayload, ApiResponse<SignUpResponse>>({
    method: 'post',
    url: '/signup',
    data: payload,
  });

export const signIn = async (payload: SignInPayload) =>
  multiwovenFetch<SignInPayload, ApiResponse<SignInResponse>>({
    method: 'post',
    url: '/login',
    data: payload,
  });

export const forgotPassword = async (payload: ForgotPasswordPayload) =>
  multiwovenFetch<ForgotPasswordPayload, ApiResponse<MessageResponse>>({
    method: 'post',
    url: '/forgot_password',
    data: payload,
  });

export const resetPassword = async (payload: ResetPasswordPayload) =>
  multiwovenFetch<ResetPasswordPayload, ApiResponse<MessageResponse>>({
    method: 'post',
    url: '/reset_password',
    data: payload,
  });

export const verifyUser = async (confirmation_token: string) =>
  multiwovenFetch<string, ApiResponse<MessageResponse>>({
    method: 'get',
    url: buildUrlWithParams('/verify_user', { confirmation_token }),
  });

export const resendUserVerification = async (payload: ForgotPasswordPayload) =>
  multiwovenFetch<ForgotPasswordPayload, ApiResponse<MessageResponse>>({
    method: 'post',
    url: `/resend_verification`,
    data: payload,
  });
