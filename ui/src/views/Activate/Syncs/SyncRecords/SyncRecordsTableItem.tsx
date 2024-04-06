import { SyncRecordResponse } from '../types';
import StatusTag from '@/components/StatusTag';
import { StatusTagVariants } from '@/components/StatusTag/StatusTag';
import { Text } from '@chakra-ui/react';

type TableItem = {
  field: string;
  data: SyncRecordResponse;
};

export const TableItem = ({ field, data }: TableItem): JSX.Element => {
  switch (field) {
    case 'status': {
      return data.attributes.status === 'success' ? (
        <StatusTag variant={StatusTagVariants.success} status='Added' />
      ) : (
        <StatusTag variant={StatusTagVariants.failed} status='Failed' />
      );
    }
    default: {
      return <Text>{data.attributes.record[field]}</Text>;
    }
  }
};
