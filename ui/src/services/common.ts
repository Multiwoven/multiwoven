export * from '@/services/axios';

type LinksType = {
  first: string;
  last: string;
  next: string;
  prev: string;
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
