import qs from 'qs';

export const buildUrlWithParams = (
  url: string,
  args: Record<string, any>,
  options?: qs.IStringifyOptions<qs.BooleanOptional>,
) => `${url}?${qs.stringify(args, options)}`;
