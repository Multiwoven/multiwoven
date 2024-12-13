import ContentContainer from '@/components/ContentContainer';
import TopBar from '@/components/TopBar';
import { fetchSyncs } from '@/services/syncs';
import { Box } from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import { FiPlus } from 'react-icons/fi';
import { SYNCS_LIST_QUERY_KEY } from '../constants';

import Loader from '@/components/Loader';
import NoActivations, { ActivationType } from '../../NoSyncs/NoSyncs';
import { CreateSyncResponse } from '@/views/Activate/Syncs/types';
import { useStore } from '@/stores';
import DataTable from '@/components/DataTable';
import { SyncsListColumns } from './SyncsListColumns';
import { Row } from '@tanstack/react-table';
<<<<<<< HEAD
import { useNavigate } from 'react-router-dom';
=======
import { useSearchParams } from 'react-router-dom';
import Pagination from '@/components/EnhancedPagination/Pagination';
>>>>>>> 87701c19 (feat(CE): added pagination to connector, models and syncs pages)

const SyncsList = (): JSX.Element => {
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useProtectedNavigate();

  const activeWorkspaceId = useStore((state) => state.workspaceId);
<<<<<<< HEAD
  const navigate = useNavigate();
=======
  const activeRole = useRoleDataStore((state) => state.activeRole);

  const pageId = searchParams.get('page');

  const onPageSelect = (page: number) => {
    setSearchParams({ page: page.toString() });
  };
>>>>>>> 87701c19 (feat(CE): added pagination to connector, models and syncs pages)

  const { data, isLoading } = useQuery({
    queryKey: [...SYNCS_LIST_QUERY_KEY, activeWorkspaceId, pageId],
    queryFn: () => fetchSyncs(pageId ? pageId : '1'),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: activeWorkspaceId > 0,
  });

  const syncList = data?.data;

  const handleOnSyncClick = (row: Row<CreateSyncResponse>) => {
    navigate(`${row.original.id}`);
  };

  if (isLoading || !syncList) return <Loader />;

  if (!isLoading && syncList.length === 0)
    return <NoActivations activationType={ActivationType.Sync} />;

  return (
    <Box
      width='100%'
      display='flex'
      flexDirection='column'
      alignItems='center'
      backgroundColor='gray.200'
    >
      <ContentContainer>
        <TopBar
          name='Syncs'
          ctaName='Add Sync'
          ctaIcon={<FiPlus color='gray.100' />}
          onCtaClicked={() => navigate('new')}
          ctaBgColor='orange.500'
          ctaColor='gray.900'
          ctaHoverBgColor='orange.400'
          isCtaVisible
        />
        <Box display='flex' flexDirection='column' gap='20px'>
          <Box border='1px' borderColor='gray.400' borderRadius={'lg'} overflowX='scroll'>
            <DataTable columns={SyncsListColumns} data={syncList} onRowClick={handleOnSyncClick} />
          </Box>
          {data?.data && data.data.length > 0 && data.links && (
            <Box display='flex' justifyContent='center'>
              <Pagination
                links={data?.links}
                currentPage={pageId ? Number(pageId) : 1}
                handlePageChange={onPageSelect}
              />
            </Box>
          )}
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default SyncsList;
