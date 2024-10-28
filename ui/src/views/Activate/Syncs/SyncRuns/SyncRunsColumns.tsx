import { SyncRunsResponse } from '../types';
import { ColumnDef } from '@tanstack/react-table';
import moment from 'moment';
import { Text, Box } from '@chakra-ui/react';
import TypeTag from '@/components/TypeTag';
import { FiCheckCircle, FiRefreshCw } from 'react-icons/fi';
import StatusTag from '@/components/StatusTag';
import { StatusTagText, StatusTagVariants } from '@/components/StatusTag/StatusTag';
import { ResultEntity } from './ResultEntity';
import formatDuration from '@/utils/formatDuration';

const StatusCell = ({ value }: { value: StatusTagVariants }) => {
  const tagText = StatusTagText[value];
  return <StatusTag variant={value} status={tagText} />;
};

const StartTimeCell = ({ value }: { value: string }) => {
  if (!value) return null;
  return (
    <Text fontSize='sm'>
      {moment(value).format('DD/MM/YYYY')} at {moment(value).format('HH:mm a')}
    </Text>
  );
};

const SyncRunTypeCell = ({ value }: { value: string }) => {
  return <TypeTag label={value} leftIcon={value === 'general' ? FiCheckCircle : FiRefreshCw} />;
};

const DurationCell = ({ value }: { value: number }) => {
  return <Text fontSize='sm'>{formatDuration(value)}</Text>;
};

const RowCountCell = ({ value, label }: { value: number; label: string }) => {
  return (
    <Text fontSize='sm'>
      {value} {label + (value > 1 ? 's' : '')}
    </Text>
  );
};

const ResultsCell = ({ value }: { value: SyncRunsResponse['attributes'] }) => {
  return (
    <Box display='flex' flexDir='row' gap={8}>
      <ResultEntity
        current_value={value.successful_rows}
        current_text_color='success.500'
        total_value={value.total_query_rows}
        result_text='Successful'
      />
      <ResultEntity
        current_value={value.failed_rows}
        current_text_color='error.500'
        total_value={value.total_query_rows}
        result_text='Failed'
      />
    </Box>
  );
};

export const SyncRunsColumns: ColumnDef<SyncRunsResponse>[] = [
  {
    accessorKey: 'attributes.status',
    header: () => <span>Status</span>,
    cell: (info) => <StatusCell value={info.getValue() as StatusTagVariants} />,
  },
  {
    accessorKey: 'attributes.started_at',
    header: () => <span>Start Time</span>,
    cell: (info) => <StartTimeCell value={info.getValue() as string} />,
  },
  {
    accessorKey: 'attributes.sync_run_type',
    header: () => <span>Sync Run Type</span>,
    cell: (info) => <SyncRunTypeCell value={info.getValue() as string} />,
  },
  {
    accessorKey: 'attributes.duration',
    header: () => <span>Duration</span>,
    cell: (info) => <DurationCell value={info.getValue() as number} />,
  },
  {
    accessorKey: 'attributes.total_query_rows',
    header: () => <span>Rows Queried</span>,
    cell: (info) => <RowCountCell value={info.getValue() as number} label='row' />,
  },
  {
    accessorKey: 'attributes.skipped_rows',
    header: () => <span>Skipped Rows</span>,
    cell: (info) => <RowCountCell value={info.getValue() as number} label='row' />,
  },
  {
    accessorKey: 'attributes',
    header: () => <span>Results</span>,
    cell: (info) => <ResultsCell value={info.getValue() as SyncRunsResponse['attributes']} />,
  },
];
