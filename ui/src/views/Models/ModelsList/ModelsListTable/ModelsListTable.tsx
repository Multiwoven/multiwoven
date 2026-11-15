import EntityItem from '@/components/EntityItem';
import { GetAllModelsResponse } from '@/services/models';
import { Text } from '@chakra-ui/react';
import { ColumnDef } from '@tanstack/react-table';
import dayjs from 'dayjs';

const ModelsListTable: ColumnDef<GetAllModelsResponse>[] = [
  {
    accessorKey: 'attributes.name',
    header: 'Name',
    cell: ({ cell }) => (
      <Text size='sm' fontWeight='semibold'>
        {cell.getValue() as string}
      </Text>
    ),
  },
  {
    accessorKey: 'attributes.connector',
    header: 'Source',
    cell: ({ cell }) => {
      const connector = cell.getValue() as GetAllModelsResponse['attributes']['connector'];
      return <EntityItem icon={connector.icon} name={connector.name} />;
    },
  },
  {
    accessorKey: 'attributes.query_type',
    header: 'Method',
    cell: (cell) => {
      const queryType = cell.getValue() as string;
      switch (queryType) {
        case 'raw_sql':
          return (
            <Text size='sm' fontWeight='semibold'>
              SQL Query
            </Text>
          );
        case 'table_selector':
          return (
            <Text size='sm' fontWeight='semibold'>
              Table Selector
            </Text>
          );
      }
      return (
        <Text size='sm' fontWeight='semibold'>
          {queryType}
        </Text>
      );
    },
  },
  {
    accessorKey: 'updated_at',
    header: 'Last Updated',
    cell: (cell) => {
      return (
        <Text size='sm' fontWeight='medium'>
          {dayjs(cell.getValue() as number).format('D MMM YYYY')}
        </Text>
      );
    },
  },
];

export default ModelsListTable;
