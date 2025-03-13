import { Outlet, useLocation } from 'react-router-dom';
import { useState, useEffect } from 'react';

import Loader from '@/components/Loader';
import { useUiConfig } from '@/utils/hooks';
import Sidebar from '@/views/Sidebar/Sidebar';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';
import ServerError from '../ServerError';
import getTitle from '@/utils/getPageTitle';

import { Box } from '@chakra-ui/layout';
import { useQuery } from '@tanstack/react-query';

import { getWorkspaces } from '@/services/settings';
import { useStore } from '@/stores';

const MainLayout = (): JSX.Element => {
  const [isLoading, setIsLoading] = useState(true);
  const { contentContainerId } = useUiConfig();
  const location = useLocation();
  useEffect(() => {
    const title = getTitle(location.pathname);
    document.title = title;
  }, [location.pathname]);

  const setActiveWorkspaceId = useStore((state) => state.setActiveWorkspaceId);
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const showToast = useCustomToast();

  const {
    data,
    isLoading: workspaceDataIsLoading,
    isError,
    isFetched,
  } = useQuery({
    queryKey: ['workspace'],
    queryFn: () => getWorkspaces(),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const workspaceData = data?.data;

  useEffect(() => {
    if (workspaceData && workspaceData.length > 0 && +activeWorkspaceId === 0) {
      setActiveWorkspaceId(workspaceData[0]?.id);
    }
    setIsLoading(false);
  }, [workspaceData]);

  useEffect(() => {
    if (isError || (!data && isFetched)) {
      showToast({
        title: 'Error: Failed to fetch workspace details.',
        description: 'Failed to fetch workspace details.',
        status: CustomToastStatus.Error,
        position: 'bottom-right',
      });
    }
  }, [isError, data, isFetched, showToast]);

  if (isError || (!data && isFetched)) {
    return <ServerError />;
  }

  if (workspaceDataIsLoading || isLoading) {
    return <Loader />;
  }

  return (
<<<<<<< HEAD
    <Box display='flex' width={'100%'} overflow='hidden' maxHeight='100vh'>
      <Sidebar />
      <Box
        pl={0}
        width={'100%'}
        maxW={'100%'}
        display='flex'
        flex={1}
        flexDir='column'
        className='flex'
        overflow='scroll'
        id={contentContainerId}
        backgroundColor='gray.200'
      >
        <Outlet />
=======
    <Prefetcher>
      <Box display='flex' width={'100%'} overflow='hidden' maxHeight='100vh'>
        <Sidebar />
        <Box
          pl={0}
          width={'100%'}
          maxW={'100%'}
          display='flex'
          flex={1}
          flexDir='column'
          alignItems='center'
          className='flex'
          overflow='scroll'
          id={contentContainerId}
          backgroundColor='gray.200'
        >
          <Outlet />
        </Box>
>>>>>>> 6e1cfad3 (fix(CE): Content centered at max width)
      </Box>
    </Box>
  );
};

export default MainLayout;
