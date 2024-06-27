import { SyncRecordResponse, SyncRecordStatus } from '../types';
import StatusTag from '@/components/StatusTag';
import { StatusTagVariants } from '@/components/StatusTag/StatusTag';
import { Text } from '@chakra-ui/react';
import ErrorLogsModal from './ErrorLogsModal';

type TableItem = {
  field: string;
  data: SyncRecordResponse;
};

export const TableItem = ({ field, data }: TableItem): JSX.Element => {
  switch (field) {
    case 'status': {
      return data.attributes.status === SyncRecordStatus.success ? (
        <StatusTag variant={StatusTagVariants.success} status='Added' />
      ) : (
        <StatusTag variant={StatusTagVariants.failed} status='Failed' />
      );
    }
    case 'error': {
      return data?.attributes?.error?.message ? (
        <ErrorLogsModal errorMessage={data?.attributes?.error?.message} />
      ) : (
        <></>
      );
    }
    default: {
      return <Text>{data.attributes.record[field]}</Text>;
    }
  }
};
