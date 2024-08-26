import ContentContainer from '@/components/ContentContainer';
import TopBar from '@/components/TopBar';
import { fetchSyncs } from '@/services/syncs';
import { Box } from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import { FiPlus } from 'react-icons/fi';
<<<<<<< HEAD
import { useNavigate } from 'react-router-dom';
import { SYNCS_LIST_QUERY_KEY, SYNC_TABLE_COLUMS } from '../constants';
import EntityItem from '@/components/EntityItem';
import Table from '@/components/Table';
=======
import { SYNCS_LIST_QUERY_KEY } from '../constants';

>>>>>>> 38bcb066 (feat(CE): Enable and Disable sync via UI)
import Loader from '@/components/Loader';
import NoActivations, { ActivationType } from '../../NoSyncs/NoSyncs';
import { CreateSyncResponse } from '@/views/Activate/Syncs/types';
import { useStore } from '@/stores';
<<<<<<< HEAD

type TableItem = {
  field: SyncColumnFields;
  data: CreateSyncResponse;
};

const TableItem = ({ field, data }: TableItem): JSX.Element => {
  switch (field) {
    case 'name':
      return (
        <Text size='sm' fontWeight={600} color='black.500'>
          {data.attributes.name}
        </Text>
      );
    case 'model':
      return (
        <EntityItem
          icon={data.attributes.model.connector.icon}
          name={data.attributes.model.connector.name}
        />
      );

    case 'destination':
      return (
        <EntityItem
          icon={data.attributes.destination.icon}
          name={data.attributes.destination.connector_name}
        />
      );

    case 'lastUpdated':
      return <Text>{moment(data.attributes.updated_at).format('DD/MM/YYYY')}</Text>;

    case 'status':
      return <StatusTag status='Active' />;
  }
};
=======
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { hasActionPermission } from '@/enterprise/utils/accessControlPermission';
import { UserActions } from '@/enterprise/types';
import useProtectedNavigate from '@/enterprise/hooks/useProtectedNavigate';
import DataTable from '@/components/DataTable';
import { SyncsListColumns } from './SyncsListColumns';
import { Row } from '@tanstack/react-table';
>>>>>>> 38bcb066 (feat(CE): Enable and Disable sync via UI)

const SyncsList = (): JSX.Element => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const navigate = useNavigate();
  const { data, isLoading } = useQuery({
    queryKey: [...SYNCS_LIST_QUERY_KEY, activeWorkspaceId],
    queryFn: () => fetchSyncs(),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: activeWorkspaceId > 0,
  });

  const syncList = data?.data;

<<<<<<< HEAD
  const tableData = useMemo(() => {
    if ((syncList as ErrorResponse)?.errors?.length > 0) {
      return {
        error: (syncList as ErrorResponse).errors[0]?.detail,
        columns: [],
        data: [],
      };
    }

    const rows = ((syncList as CreateSyncResponse[]) ?? [])?.map((data) => {
      return SYNC_TABLE_COLUMS.reduce(
        (acc, { key }) => ({
          [key]: <TableItem field={key} data={data} />,
          id: data.id,
          ...acc,
        }),
        {},
      );
    });

    return {
      columns: SYNC_TABLE_COLUMS,
      data: rows,
      error: '',
    };
  }, [data]);

  const handleOnSyncClick = (row: Record<'id', string>) => {
    navigate(`${row.id}`);
  };

  if (isLoading) return <Loader />;
=======
  const handleOnSyncClick = (row: Row<CreateSyncResponse>) => {
    navigate({ to: `${row.original.id}`, location: 'sync_run', action: UserActions.Read });
  };

  if (isLoading || activeRole === null || !syncList) return <Loader />;
>>>>>>> 38bcb066 (feat(CE): Enable and Disable sync via UI)

  if (!isLoading && syncList.length === 0)
    return <NoActivations activationType={ActivationType.Sync} />;

  return (
    <Box
      width='100%'
      display='flex'
      flexDirection='column'
      alignItems='center'
      backgroundColor='gray.200'
    >
      <ContentContainer>
        <TopBar
          name='Syncs'
          ctaName='Add Sync'
          ctaIcon={<FiPlus color='gray.100' />}
          onCtaClicked={() => navigate('new')}
          ctaBgColor='orange.500'
          ctaColor='gray.900'
          ctaHoverBgColor='orange.400'
          isCtaVisible
        />
        <Box border='1px' borderColor='gray.400' borderRadius={'lg'} overflowX='scroll'>
          <DataTable columns={SyncsListColumns} data={syncList} onRowClick={handleOnSyncClick} />
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default SyncsList;
