export * from '@/services/axios';

export type APIRequestMethod = 'get' | 'post' | 'put' | 'delete';

export type LinksType = {
  first: string;
  last: string;
  next: string | null;
  prev: string | null;
  self: string;
};

export type ErrorResponse = {
  status: number;
  title: string;
  detail: string;
};

export type ApiResponse<T> = {
  data?: T;
  status: number;
  errors?: ErrorResponse[];
  links?: LinksType;
};
