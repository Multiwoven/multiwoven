import { useSearchParams } from 'react-router-dom';

const buildFilter = <T extends Record<string, string | string[]>>(filters: T) => {
  const queryFilter: Record<string, string | string[]> = {};
  Object.keys(filters).forEach((key) => {
    if (filters[key] !== null && filters[key] !== undefined) {
      queryFilter[key] = filters[key];
    }
  });
  return queryFilter;
};

const parseQueryParams = <T extends Record<string, string | string[]>>(
  params: URLSearchParams,
  defaultFilters: T,
): T => {
  const parsedFilters: Record<string, string | string[] | null> = { ...defaultFilters };
  if ([...params.keys()].length === 0) {
    return parsedFilters as T;
  }
  Object.keys(parsedFilters).forEach((key) => {
    if (params.has(key)) {
      parsedFilters[key] = Array.isArray(defaultFilters[key])
        ? params.getAll(key)
        : params.get(key);
    }
  });
  return parsedFilters as T;
};

const useFilters = <T extends Record<string, string | string[]>>(defaultFilters: T) => {
  const [searchParams, setSearchParams] = useSearchParams();

  const updateFilters = (newFilters: T) => {
    setSearchParams(buildFilter(newFilters));
  };

  const filters = parseQueryParams(searchParams, defaultFilters);
  return { filters, updateFilters };
};

export default useFilters;
