import EntityItem from '@/components/EntityItem';
import { GetAllModelsResponse } from '@/services/models';
import { Text } from '@chakra-ui/react';
import { ColumnDef } from '@tanstack/react-table';
import dayjs from 'dayjs';

const ModelsListTable: ColumnDef<GetAllModelsResponse>[] = [
  {
    accessorKey: 'attributes.name',
    header: 'Name',
    cell: (cell) => {
      return (
        <EntityItem
          icon={cell.row.original.attributes.connector.icon}
          name={cell.row.original.attributes.name}
        />
      );
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
