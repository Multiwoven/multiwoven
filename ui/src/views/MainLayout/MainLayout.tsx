import { useUiConfig } from '@/utils/hooks';
import Sidebar from '@/views/Sidebar/Sidebar';
import { Box } from '@chakra-ui/layout';
import { Outlet } from 'react-router-dom';
import Loader from '@/components/Loader';
import { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getWorkspaces } from '@/services/settings';
import { useStore } from '@/stores';

const MainLayout = (): JSX.Element => {
  const [isLoading, setIsLoading] = useState(true);
  const { contentContainerId } = useUiConfig();

  const setActiveWorkspaceId = useStore((state) => state.setActiveWorkspaceId);

  const { data } = useQuery({
    queryKey: ['workspace'],
    queryFn: () => getWorkspaces(),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const workspaceData = data?.data;

  useEffect(() => {
    if (workspaceData && workspaceData.length > 0) {
      setActiveWorkspaceId(workspaceData[0]?.id);
      setIsLoading(false);
    }
  }, [workspaceData]);

  if (isLoading) {
    return <Loader />;
  }

  return (
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
      </Box>
    </Box>
  );
};

export default MainLayout;
