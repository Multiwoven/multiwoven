import { Box, Text } from '@chakra-ui/react';
import { SyncRunsColumnFields, SyncRunsResponse } from '../types';
import moment from 'moment';
import StatusTag from '@/components/StatusTag';
import { ResultEntity } from './ResultEntity';
import { StatusTagText, StatusTagVariants } from '@/components/StatusTag/StatusTag';

type TableItem = {
  field: SyncRunsColumnFields;
  data: SyncRunsResponse;
};

export const TableItem = ({ field, data }: TableItem): JSX.Element => {
  switch (field) {
    case 'start_time':
      return (
        <Text fontSize='sm'>
          {moment(data.attributes.started_at).format('DD/MM/YYYY')} at{' '}
          {moment(data.attributes.started_at).format('HH:mm a')}
        </Text>
      );

    case 'duration':
      return <Text fontSize='sm'>{data.attributes.duration?.toPrecision(3)} seconds</Text>;

    case 'rows_queried':
      return <Text fontSize='sm'>{data.attributes.total_query_rows} rows</Text>;

    case 'status': {
      const variant = data.attributes.status as StatusTagVariants;
      const tagText = StatusTagText[variant];

      return <StatusTag variant={variant} status={tagText} />;
    }

    case 'results':
      return (
        <Box display='flex' flexDir='row' gap={8}>
          <ResultEntity
            current_value={data.attributes.successful_rows}
            current_text_color='success.500'
            total_value={data.attributes.total_query_rows}
            result_text='Successful'
          />
          <ResultEntity
            current_value={data.attributes.failed_rows}
            current_text_color='error.500'
            total_value={data.attributes.total_query_rows}
            result_text='Failed'
          />
        </Box>
      );
  }
};
