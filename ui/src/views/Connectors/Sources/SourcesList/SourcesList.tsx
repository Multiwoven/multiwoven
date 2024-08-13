import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Box } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';
import TopBar from '@/components/TopBar';
<<<<<<< HEAD
import { useNavigate } from 'react-router-dom';
import { SOURCES_LIST_QUERY_KEY, CONNECTOR_LIST_COLUMNS } from '@/views/Connectors/constant';
import Table from '@/components/Table';
=======
import { SOURCES_LIST_QUERY_KEY } from '@/views/Connectors/constant';
>>>>>>> a6ab37fc (refactor(CE): created common connector lists component)
import { getUserConnectors } from '@/services/connectors';
import ContentContainer from '@/components/ContentContainer';
import Loader from '@/components/Loader';
import NoConnectors from '@/views/Connectors/NoConnectors';
<<<<<<< HEAD
import StatusTag from '@/components/StatusTag';

type TableItem = {
  field: ConnectorTableColumnFields;
  attributes: ConnectorAttributes;
};

const TableItem = ({ field, attributes }: TableItem): JSX.Element => {
  switch (field) {
    case 'icon':
      return <EntityItem icon={attributes.icon} name={attributes.connector_name} />;

    case 'updated_at':
      return (
        <Text fontSize='14px' fontWeight={500}>
          {moment(attributes?.updated_at).format('DD/MM/YY')}
        </Text>
      );

    case 'status':
      return <StatusTag status='Active' />;

    default:
      return (
        <Text fontSize='14px' fontWeight={600}>
          {attributes?.[field]}
        </Text>
      );
  }
};
=======
import { useStore } from '@/stores';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast/index';
import titleCase from '@/utils/TitleCase';
import { useRoleDataStore } from '@/enterprise/store/useRoleDataStore';
import { UserActions } from '@/enterprise/types';
import { hasActionPermission } from '@/enterprise/utils/accessControlPermission';
import useProtectedNavigate from '@/enterprise/hooks/useProtectedNavigate';
import { ConnectorsListColumns } from '@/views/Connectors/ConnectorsListColumns/ConnectorsListColumns';
import DataTable from '@/components/DataTable';
>>>>>>> a6ab37fc (refactor(CE): created common connector lists component)

const SourcesList = (): JSX.Element | null => {
  const navigate = useNavigate();
  const { data, isLoading } = useQuery({
    queryKey: SOURCES_LIST_QUERY_KEY,
    queryFn: () => getUserConnectors('Source'),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

<<<<<<< HEAD
  const connectors = data?.data;

  const tableData = useMemo(() => {
    if (connectors && connectors?.length > 0) {
      const rows = connectors.map(({ attributes, id }) => {
        return CONNECTOR_LIST_COLUMNS.reduce(
          (acc, { key }) => ({
            [key]: <TableItem field={key} attributes={attributes} />,
            id,
            ...acc,
          }),
          {},
        );
      });

      return {
        columns: CONNECTOR_LIST_COLUMNS,
        data: rows,
      };
    }
  }, [data]);

  if (isLoading) return <Loader />;

  if (!isLoading && !tableData) return <NoConnectors connectorType='source' />;

=======
  if (isLoading || activeRole === null) return <Loader />;

  if (data?.data?.length === 0 || !data) return <NoConnectors connectorType='source' />;

  if (data?.errors) {
    data.errors?.forEach((error) => {
      showToast({
        duration: 5000,
        isClosable: true,
        position: 'bottom-right',
        colorScheme: 'red',
        status: CustomToastStatus.Warning,
        title: titleCase(error.detail),
      });
    });
    return <NoConnectors connectorType='source' />;
  }

  const hasPermission = hasActionPermission(activeRole, 'model', UserActions.Create);

>>>>>>> a6ab37fc (refactor(CE): created common connector lists component)
  return (
    <Box width='100%' display='flex' flexDirection='column' alignItems='center'>
      <ContentContainer>
        <TopBar
          name='Sources'
          ctaName='Add Source'
          ctaIcon={<FiPlus color='gray.100' />}
          onCtaClicked={() => navigate('new')}
          ctaButtonVariant='solid'
          isCtaVisible
        />
<<<<<<< HEAD
        {tableData ? (
          <Table data={tableData} onRowClick={(row) => navigate(`/setup/sources/${row?.id}`)} />
        ) : null}
=======
        <DataTable
          data={data?.data}
          columns={ConnectorsListColumns}
          onRowClick={(row) =>
            navigate({
              to: `/setup/sources/${row?.original?.id}`,
              location: 'connector',
              action: UserActions.Update,
            })
          }
        />
>>>>>>> a6ab37fc (refactor(CE): created common connector lists component)
      </ContentContainer>
    </Box>
  );
};

export default SourcesList;
