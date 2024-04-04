import { multiwovenFetch } from './common';

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

export type SignInErrorResponse = {
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
  errors?: SignInErrorResponse[];
};

export type AuthResponse = {
  type: string;
  id: string;
  attributes: {
    token: string;
  };
  errors?: Array<{
    source: {
      [key: string]: string;
    };
  }>;
};

export type ApiResponse<T> = {
  data?: T;
  status: number;
};

export const signUp = async (payload: SignUpPayload) =>
  multiwovenFetch<SignUpPayload, ApiResponse<AuthResponse>>({
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
