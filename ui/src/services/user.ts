import { multiwovenFetch } from './common';

export type ProfileAPIResponse = {
  data?: {
    id: number;
    type: string;
    attributes: {
      name: string;
      email: string;
    };
  };
};

export type LogoutAPIResponse = {
  data?: {
    type: string;
    id: string;
    attributes: {
      message: string;
    };
  };
  error?: string;
};

export const getUserProfile = async (): Promise<ProfileAPIResponse> =>
  multiwovenFetch<null, ProfileAPIResponse>({
    method: 'get',
    url: '/users/me',
  });

export const logout = async (): Promise<LogoutAPIResponse> =>
  multiwovenFetch<null, LogoutAPIResponse>({
    method: 'delete',
    url: '/logout',
  });
