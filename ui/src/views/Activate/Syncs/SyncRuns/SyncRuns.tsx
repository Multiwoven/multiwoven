import { useNavigate, useParams } from 'react-router-dom';
import { useMemo } from 'react';
import { Box } from '@chakra-ui/react';
import Loader from '@/components/Loader';
import Pagination from '@/components/EnhancedPagination';
import { useStore } from '@/stores';
import useSyncRuns from '@/hooks/syncs/useSyncRuns';
import { SyncRunsColumns } from './SyncRunsColumns';
import DataTable from '@/components/DataTable';
import { Row } from '@tanstack/react-table';
import { SyncRunsResponse } from '../types';
import RowsNotFound from '@/components/DataTable/RowsNotFound';
import useFilters from '@/hooks/useFilters';

const SyncRuns = () => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const { filters, updateFilters } = useFilters({ page: '1' });
  const { syncId } = useParams();
  const navigate = useNavigate();

  const { data, isLoading } = useSyncRuns(
    syncId as string,
    Number(filters.page),
    activeWorkspaceId,
  );

  const handleOnSyncClick = (row: Row<SyncRunsResponse>) => {
    navigate(`run/${row.original.id}`);
  };

  const syncList = data?.data;

  const allColumns = useMemo(() => [...SyncRunsColumns], [SyncRunsColumns]);

  return (
    <Box width='100%' pt={'20px'}>
      {!syncList && isLoading ? (
        <Loader />
      ) : (
        <Box display='flex' flexDirection='column' gap='20px'>
          {data?.data?.length === 0 || !data?.data ? (
            <RowsNotFound />
          ) : (
            <DataTable data={data?.data} columns={allColumns} onRowClick={handleOnSyncClick} />
          )}
          {data?.links && (
            <Box display='flex' justifyContent='center'>
              <Pagination
                links={data.links}
                currentPage={filters.page ? Number(filters.page) : 1}
                handlePageChange={(page) => updateFilters({ ...filters, page: page.toString() })}
              />
            </Box>
          )}
        </Box>
      )}
    </Box>
  );
};

export default SyncRuns;
