import { useQuery } from '@tanstack/react-query';
import { useParams } from 'react-router-dom';
import { getSyncRunsById } from '@/services/syncs';
import { useMemo } from 'react';
import { SYNC_RUNS_COLUMNS } from '@/views/Activate/Syncs/constants';
import { Box } from '@chakra-ui/react';
import Loader from '@/components/Loader';
import Table from '@/components/Table';
import { TableItem } from '@/views/Activate/Syncs/SyncRuns/SyncRunTableItem';

const SyncRuns = () => {
  const { syncId } = useParams();

  const { data, isLoading } = useQuery({
    queryKey: ['activate', 'sync-runs', syncId],
    queryFn: () => getSyncRunsById(syncId as string),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  const syncList = data?.data;

  const tableData = useMemo(() => {
    const rows = (syncList ?? [])?.map((data) => {
      return SYNC_RUNS_COLUMNS.reduce(
        (acc, { key }) => ({
          [key]: <TableItem field={key} data={data} />,
          id: data.id,
          ...acc,
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

  return (
    <Box width='100%' pt={'20px'}>
      {!syncList && isLoading ? <Loader /> : <Table data={tableData} />}
    </Box>
  );
};

export default SyncRuns;
