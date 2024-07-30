import { useQuery } from '@tanstack/react-query';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { getSyncRunsBySyncId } from '@/services/syncs';
import { useMemo, useState, useEffect } from 'react';
import { Box, Image, Text } from '@chakra-ui/react';
import Loader from '@/components/Loader';
import Pagination from '@/components/Pagination';
<<<<<<< HEAD
=======
import { useStore } from '@/stores';
import useProtectedNavigate from '@/enterprise/hooks/useProtectedNavigate';
import { UserActions } from '@/enterprise/types';
import useSyncRuns from '@/hooks/syncs/useSyncRuns';
import { SyncRunsColumns } from './SyncRunsColumns';
import DataTable from '@/components/DataTable';
import SyncRunEmptyImage from '@/assets/images/empty-state-illustration.svg';
>>>>>>> 8b6bcbbd (feat(CE): Add sync run type column)

const SyncRuns = () => {
  const { syncId } = useParams();
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();

  const pageId = searchParams.get('page');
  const [currentPage, setCurrentPage] = useState(Number(pageId) || 1);

  useEffect(() => {
    setSearchParams({ page: currentPage.toString() });
  }, [currentPage, setSearchParams]);

  const { data, isLoading } = useQuery({
    queryKey: ['activate', 'sync-runs', syncId, 'page-' + currentPage],
    queryFn: () => getSyncRunsBySyncId(syncId as string, currentPage.toString()),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const handleOnSyncClick = (row: Record<'id', string>) => {
    navigate(`run/${row.id}`);
  };

  const syncList = data?.data;

  const allColumns = useMemo(() => [...SyncRunsColumns], [SyncRunsColumns]);

  const handleNextPage = () => {
    setCurrentPage((prevPage) => Math.min(prevPage + 1));
  };

  const handlePrevPage = () => {
    setCurrentPage((prevPage) => Math.max(prevPage - 1, 1));
  };

  return (
    <Box width='100%' pt={'20px'}>
      {!syncList && isLoading ? (
        <Loader />
      ) : (
        <Box>
          {data?.data?.length === 0 || !data?.data ? (
            <Box
              display='flex'
              w='fit-content'
              mx='auto'
              flexDirection='column'
              gap='20px'
              mt='10%'
            >
              <Image src={SyncRunEmptyImage} w='175px' h='132px' />
              <Text fontSize='xl' mx='auto' color='gray.600' fontWeight='semibold'>
                No rows found
              </Text>
            </Box>
          ) : (
            <DataTable data={data?.data} columns={allColumns} onRowClick={handleOnSyncClick} />
          )}
          <Box display='flex' flexDirection='row-reverse' pt='10px'>
            <Pagination
              currentPage={currentPage}
              isPrevPageEnabled={data?.links?.prev != null}
              isNextPageEnabled={data?.links?.next != null}
              handleNextPage={handleNextPage}
              handlePrevPage={handlePrevPage}
            />
          </Box>
        </Box>
      )}
    </Box>
  );
};

export default SyncRuns;
