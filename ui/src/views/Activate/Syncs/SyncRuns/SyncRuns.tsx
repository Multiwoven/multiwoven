import { useQuery } from '@tanstack/react-query';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { getSyncRunsBySyncId } from '@/services/syncs';
import { useMemo, useState, useEffect } from 'react';
import { SYNC_RUNS_COLUMNS } from '@/views/Activate/Syncs/constants';
import { Box } from '@chakra-ui/react';
import Loader from '@/components/Loader';
import Table from '@/components/Table';
import { TableItem } from '@/views/Activate/Syncs/SyncRuns/SyncRunTableItem';
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
import { Row } from '@tanstack/react-table';
import { SyncRunsResponse } from '../types';
>>>>>>> 966eb997 (fix(CE): fixed sync runs on click function)

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

<<<<<<< HEAD
  const handleOnSyncClick = (row: Record<'id', string>) => {
    navigate(`run/${row.id}`);
=======
  const handleOnSyncClick = (row: Row<SyncRunsResponse>) => {
    navigate({ to: `run/${row.original.id}`, location: 'sync_record', action: UserActions.Read });
>>>>>>> 966eb997 (fix(CE): fixed sync runs on click function)
  };

  const syncList = data?.data;

  const tableData = useMemo(() => {
    const rows = (syncList ?? []).map((data) => {
      return SYNC_RUNS_COLUMNS.reduce(
        (acc, { key }) => ({
          ...acc,
          [key]: <TableItem field={key} data={data} />,
          id: data.id,
        }),
        {},
      );
    });

    return {
      columns: SYNC_RUNS_COLUMNS,
      data: rows,
      error: '',
    };
  }, [data]);

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
          <Table data={tableData} onRowClick={handleOnSyncClick} />
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
