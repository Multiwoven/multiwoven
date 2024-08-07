import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import Loader from '@/components/Loader';
import NoAccess from '../NoAccess';
import { getWorkspaces } from '@/services/settings';
import { useStore } from '@/stores';
import { useErrorToast } from '@/hooks/useErrorToast';
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { getRoles } from '@/enterprise/services/settings';

type PrefetcherProps = {
  children: JSX.Element;
};

const Prefetcher = ({ children }: PrefetcherProps): JSX.Element => {
  const [isLoading, setIsLoading] = useState(true);
  const setActiveWorkspaceId = useStore((state) => state.setActiveWorkspaceId);
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const setRolesData = useRoleDataStore((state) => state.setRolesData);

  const errorToast = useErrorToast();

  // Fetch workspaces
  const {
    data: workspaceData,
    isLoading: workspaceIsLoading,
    isError: workspaceIsError,
    isFetched: workspaceIsFetched,
  } = useQuery({
    queryKey: ['workspace'],
    queryFn: getWorkspaces,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  errorToast(
    'Failed to fetch workspace details.',
    workspaceIsError,
    workspaceData,
    workspaceIsFetched,
  );

  useEffect(() => {
    if (workspaceData?.data && workspaceData.data.length > 0 && activeWorkspaceId === 0) {
      setActiveWorkspaceId(workspaceData.data[0]?.id);
    }
  }, [workspaceData, activeWorkspaceId, setActiveWorkspaceId]);

  // Fetch roles only if workspace is loaded
  const {
    data: rolesData,
    isError: rolesIsError,
    isFetched: rolesIsFetched,
  } = useQuery({
    queryKey: ['roles', activeWorkspaceId],
    queryFn: () => getRoles(),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: !!activeWorkspaceId,
  });

  errorToast('Failed to fetch roles.', rolesIsError, rolesData, rolesIsFetched);

  useEffect(() => {
    if (rolesData) {
      setRolesData(rolesData.data);
      setIsLoading(false);
    }
  }, [rolesData, setRolesData]);

  if (workspaceIsError || (!workspaceData && workspaceIsFetched)) {
    return <NoAccess />;
  }

  if (rolesIsError || (!rolesData && rolesIsFetched)) {
    return <NoAccess />;
  }

  if (isLoading || workspaceIsLoading) {
    return <Loader />;
  }

  return children;
};

export default Prefetcher;
