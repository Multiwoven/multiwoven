import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Box, Text } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';
import TopBar from '@/components/TopBar';
import { useNavigate } from 'react-router-dom';
import { SOURCES_LIST_QUERY_KEY, CONNECTOR_LIST_COLUMNS } from '@/views/Connectors/constant';
import Table from '@/components/Table';
import { getUserConnectors } from '@/services/connectors';
import { ConnectorAttributes, ConnectorTableColumnFields } from '../../types';
import moment from 'moment';
import ContentContainer from '@/components/ContentContainer';
import EntityItem from '@/components/EntityItem';
import Loader from '@/components/Loader';
import NoConnectors from '@/views/Connectors/NoConnectors';
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

const SourcesList = (): JSX.Element | null => {
  const navigate = useNavigate();
  const { data, isLoading } = useQuery({
    queryKey: SOURCES_LIST_QUERY_KEY,
    queryFn: () => getUserConnectors('Source'),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

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
        {tableData ? (
          <Table data={tableData} onRowClick={(row) => navigate(`/setup/sources/${row?.id}`)} />
        ) : null}
      </ContentContainer>
    </Box>
  );
};

export default SourcesList;
