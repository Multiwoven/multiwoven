import { useQuery } from '@tanstack/react-query';
import { getSyncRunsBySyncId } from '@/services/syncs';

const useSyncRuns = (syncId: string, currentPage: number, activeWorkspaceId: number) => {
  return useQuery({
    queryKey: ['activate', 'sync-runs', syncId, 'page-' + currentPage, activeWorkspaceId],
    queryFn: () => getSyncRunsBySyncId(syncId, currentPage.toString()),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: activeWorkspaceId > 0,
  });
};

export default useSyncRuns;
