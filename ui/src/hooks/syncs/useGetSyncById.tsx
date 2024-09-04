import { useQuery } from '@tanstack/react-query';
import { getSyncById } from '@/services/syncs';

const useGetSyncById = (syncId: string, activeWorkspaceId: number) => {
  return useQuery({
    queryKey: ['sync', syncId, activeWorkspaceId],
    queryFn: () => getSyncById(syncId),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: !!syncId && activeWorkspaceId > 0,
  });
};

export default useGetSyncById;
