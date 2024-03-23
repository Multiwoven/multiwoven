import ContentContainer from '@/components/ContentContainer';
import EntityItem from '@/components/EntityItem';
import Loader from '@/components/Loader';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import Table from '@/components/Table';
import { getUserConnectors } from '@/services/connectors';
import NoConnectors from '@/views/Connectors/NoConnectors';
import { CONNECTOR_LIST_COLUMNS } from '@/views/Connectors/constant';
import { ConnectorAttributes, ConnectorTableColumnFields } from '@/views/Connectors/types';
import { Box, Text } from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import moment from 'moment';
import { useContext, useMemo } from 'react';
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
      return <Text size='sm'>{moment(attributes?.updated_at).format('DD/MM/YY')}</Text>;

    case 'status':
      return <StatusTag status='Active' />;

    default:
      return (
        <Text size='sm' fontWeight={600}>
          {attributes?.[field]}
        </Text>
      );
  }
};

const SelectModelSourceForm = (): JSX.Element | null => {
  const { stepInfo, handleMoveForward } = useContext(SteppedFormContext);

  const { data, isLoading } = useQuery({
    queryKey: ['models', 'data-source'],
    queryFn: () => getUserConnectors('Source'),
    refetchOnMount: false,
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

  if (!connectors) return null;

  if (!isLoading && !tableData) return <NoConnectors connectorType='source' />;

  const handleOnRowClick = (row: unknown) => {
    if (stepInfo?.formKey) {
      handleMoveForward(stepInfo?.formKey, row);
    }
  };

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        {isLoading || !tableData ? (
          <Loader />
        ) : (
          <Table data={tableData} onRowClick={(row) => handleOnRowClick(row)} />
        )}
      </ContentContainer>
    </Box>
  );
};

export default SelectModelSourceForm;
