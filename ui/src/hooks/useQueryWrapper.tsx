import {
  useQuery,
  UseQueryOptions,
  UseQueryResult,
  QueryFunction,
  QueryKey,
} from '@tanstack/react-query';
import { useStore } from '@/stores';

// Custom hook for queries with workspace ID check
const useQueryWrapper = <TData, TError = unknown>(
  key: QueryKey,
  queryFn: QueryFunction<TData>,
  options?: Omit<UseQueryOptions<TData, TError>, 'queryKey' | 'queryFn'>,
): UseQueryResult<TData, TError> => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const queryOptions: UseQueryOptions<TData, TError> = {
    ...options,
    queryKey: [...key, activeWorkspaceId],
    queryFn: activeWorkspaceId > 0 ? queryFn : () => Promise.resolve(null as unknown as TData),
    enabled: activeWorkspaceId > 0,
  };

  return useQuery<TData, TError>(queryOptions);
};

export default useQueryWrapper;
