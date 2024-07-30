import { Box, Text } from '@chakra-ui/react';
import { SyncRunsColumnFields, SyncRunsResponse } from '../types';
import moment from 'moment';
import StatusTag from '@/components/StatusTag';
import { ResultEntity } from './ResultEntity';
import { StatusTagText, StatusTagVariants } from '@/components/StatusTag/StatusTag';
import TypeTag from '@/components/TypeTag';
import { FiCheckCircle, FiRefreshCw } from 'react-icons/fi';

type TableItemProps = {
  field: SyncRunsColumnFields;
  data: SyncRunsResponse;
};

const StartTime = ({ started_at }: { started_at: string | null }) => {
  if (!started_at) return null;

  return (
    <Text fontSize='sm'>
      {moment(started_at).format('DD/MM/YYYY')} at {moment(started_at).format('HH:mm a')}
    </Text>
  );
};

const Duration = ({ duration }: { duration: number | null }) => {
  if (duration == null) return null;

  return <Text fontSize='sm'>{duration.toPrecision(3)} seconds</Text>;
};

const SyncRunType = ({ sync_run_type }: { sync_run_type: string }) => (
  <TypeTag
    label={sync_run_type}
    leftIcon={sync_run_type === 'general' ? FiCheckCircle : FiRefreshCw}
  />
);

const SkippedRows = ({ skipped_rows }: { skipped_rows: number }) => (
  <Text fontSize='sm'>{skipped_rows} rows</Text>
);

const RowsQueried = ({ total_query_rows }: { total_query_rows: number }) => (
  <Text fontSize='sm'>{total_query_rows} rows</Text>
);

const Status = ({ status }: { status: StatusTagVariants }) => {
  const tagText = StatusTagText[status];

  return <StatusTag variant={status} status={tagText} />;
};

const Results = ({
  successful_rows,
  failed_rows,
  total_query_rows,
}: {
  successful_rows: number;
  failed_rows: number;
  total_query_rows: number;
}) => (
  <Box display='flex' flexDir='row' gap={8}>
    <ResultEntity
      current_value={successful_rows}
      current_text_color='success.500'
      total_value={total_query_rows}
      result_text='Successful'
    />
    <ResultEntity
      current_value={failed_rows}
      current_text_color='error.500'
      total_value={total_query_rows}
      result_text='Failed'
    />
  </Box>
);

export const TableItem = ({ field, data }: TableItemProps): JSX.Element => {
  if (!data?.attributes) return <></>;

  const {
    started_at,
    duration,
    sync_run_type,
    skipped_rows,
    total_query_rows,
    status,
    successful_rows,
    failed_rows,
  } = data.attributes;

  switch (field) {
    case 'start_time':
<<<<<<< HEAD
      return (
        <Text fontSize='sm'>
          {moment(data.attributes.started_at).format('DD/MM/YYYY')} at{' '}
          {moment(data.attributes.started_at).format('HH:mm a')}
        </Text>
      );

=======
      return <StartTime started_at={started_at} />;
>>>>>>> 8b6bcbbd (feat(CE): Add sync run type column)
    case 'duration':
      return <Duration duration={duration} />;
    case 'sync_run_type':
      return <SyncRunType sync_run_type={sync_run_type} />;
    case 'skipped_rows':
      return <SkippedRows skipped_rows={skipped_rows} />;
    case 'rows_queried':
      return <RowsQueried total_query_rows={total_query_rows} />;
    case 'status':
      return <Status status={status as StatusTagVariants} />;
    case 'results':
      return (
        <Results
          successful_rows={successful_rows}
          failed_rows={failed_rows}
          total_query_rows={total_query_rows}
        />
      );
    default:
      return <></>;
  }
};

export default TableItem;
