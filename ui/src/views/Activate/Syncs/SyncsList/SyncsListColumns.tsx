import { ColumnDef } from '@tanstack/react-table';
import { CreateSyncResponse } from '../types';
import StatusTag from '@/components/StatusTag';
import { StatusTagVariants } from '@/components/StatusTag/StatusTag';
import { Text } from '@chakra-ui/react';
import dayjs from 'dayjs';
import EntityItem from '@/components/EntityItem';
import { useStore } from '@/stores';

export const SyncsListColumns: ColumnDef<CreateSyncResponse>[] = [
  {
    accessorKey: `attributes.name`,
    header: () => <span>Name</span>,
    cell: (info) => (
      <Text size='sm' fontWeight={600} color='black.500'>
        {info.renderValue() as string}
      </Text>
    ),
  },
  {
    accessorKey: 'attributes.model',
    header: () => <h1>Model</h1>,
    cell: (info) => {
      const model = info.getValue() as CreateSyncResponse['attributes']['model'];
      return <EntityItem icon={model.connector.icon} name={model.name} />;
    },
  },
  {
    accessorKey: 'attributes.destination',
    header: () => <h1>Destination</h1>,
    cell: (row) => {
      const activeWorkspaceId = useStore.getState().workspaceId;
      const destination = row.row.original.attributes.destination;

<<<<<<< HEAD
      return +activeWorkspaceId === 18 &&
        destination.connector_name.toLowerCase() === 'postgresql' ? (
        <EntityItem
          icon='https://squared.ai/wp-content/uploads/2024/03/apple-touch-icon.png'
          name='AIS Datastore'
        />
      ) : (
        <EntityItem icon={destination.icon} name={destination.connector_name} />
      );
=======
      return <EntityItem icon={destination.icon} name={destination.name} />;
>>>>>>> 67a2fcc2 (refactor(CE): changed destination name in Syncs from Connector Name to Name (#992))
    },
  },
  {
    accessorKey: 'attributes.updated_at',
    header: () => <h1>Last Updated</h1>,
    cell: (info) => {
      return (
        <Text size='sm' fontWeight='medium'>
          {dayjs(info.getValue() as number).format('DD MMM YYYY')}
        </Text>
      );
    },
  },
  {
    accessorKey: 'attributes.status',
    header: () => <h1>Status</h1>,
    cell: (info) => {
      const status = info.getValue() as string;
      return (
        <StatusTag
          status={status !== 'disabled' ? 'Active' : 'Disabled'}
          variant={status !== 'disabled' ? StatusTagVariants.success : StatusTagVariants.paused}
        />
      );
    },
  },
];
