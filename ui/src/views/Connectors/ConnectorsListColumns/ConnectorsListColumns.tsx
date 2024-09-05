import { ConnectorItem } from '../types';
import { ColumnDef } from '@tanstack/react-table';
import { Text } from '@chakra-ui/react';
import EntityItem from '@/components/EntityItem';
import StatusTag from '@/components/StatusTag';
import dayjs from 'dayjs';

export const ConnectorsListColumns: ColumnDef<ConnectorItem>[] = [
  {
    accessorKey: 'attributes.name',
    header: () => <span>Name</span>,
    cell: (info) => (
      <Text fontSize='14px' fontWeight={600}>
        {info.getValue() as string}
      </Text>
    ),
  },
  {
    accessorKey: 'attributes',
    header: () => <span>Type</span>,
    cell: (info) => (
      <EntityItem
        icon={(info.getValue() as ConnectorItem['attributes']).icon}
        name={(info.getValue() as ConnectorItem['attributes']).connector_name}
      />
    ),
  },
  {
    accessorKey: 'attributes.updated_at',
    header: () => <span>Updated At</span>,
    cell: (info) => (
      <Text fontSize='14px' fontWeight={500}>
        {dayjs(info.getValue() as number).format('DD/MM/YY')}
      </Text>
    ),
  },
  {
    accessorKey: 'attributes.status',
    header: () => <span>Status</span>,
    cell: () => <StatusTag status='Active' />,
  },
];
