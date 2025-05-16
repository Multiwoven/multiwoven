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
import { useNavigate } from 'react-router-dom';
import useFilters from '@/hooks/useFilters';
import Pagination from '@/components/EnhancedPagination';

const SyncsList = (): JSX.Element => {
  const navigate = useNavigate();
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const { filters, updateFilters } = useFilters({ page: '1' });

  const { data, isLoading } = useQuery({
    queryKey: [...SYNCS_LIST_QUERY_KEY, activeWorkspaceId, filters.page],
    queryFn: () => fetchSyncs(filters.page as string, '10'),
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
        <Box border='1px' borderColor='gray.400' borderRadius={'lg'} overflowX='scroll'>
          <DataTable columns={SyncsListColumns} data={syncList} onRowClick={handleOnSyncClick} />
        </Box>
        {data?.links && data.data && data.data.length > 0 && (
          <Box display='flex' justifyContent='center' mt='20px'>
            <Pagination
              links={data.links}
              currentPage={filters.page ? Number(filters.page) : 1}
              handlePageChange={(page) => updateFilters({ ...filters, page: page.toString() })}
            />
          </Box>
        )}
      </ContentContainer>
    </Box>
  );
};

export default SyncsList;