import ContentContainer from '@/components/ContentContainer';
import Loader from '@/components/Loader';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getUserConnectors } from '@/services/connectors';
import NoConnectors from '@/views/Connectors/NoConnectors';
import { Box } from '@chakra-ui/react';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import { ConnectorItem, ConnectorListResponse } from '@/views/Connectors/types';
import { ConnectorsListColumns } from '@/views/Connectors/ConnectorsListColumns/ConnectorsListColumns';
import DataTable from '@/components/DataTable';
import { useContext, useState } from 'react';
import { Row } from '@tanstack/react-table';
import SearchBar from '@/components/SearchBar/SearchBar';

const SelectModelSourceForm = (): JSX.Element | null => {
  const { stepInfo, handleMoveForward } = useContext(SteppedFormContext);
  const [searchTerm, setSearchTerm] = useState('');

  const { data, isLoading } = useQueryWrapper<ConnectorListResponse, Error>(
    ['models', 'data-source'],
    () => getUserConnectors('Source'),
    {
      refetchOnMount: false,
      refetchOnWindowFocus: false,
    },
  );

  const connectors = data?.data;

  if (!connectors) return null;

  if (!isLoading && !connectors) return <NoConnectors connectorType='source' />;

  const handleOnRowClick = (row: Row<ConnectorItem>) => {
    if (stepInfo?.formKey) {
      handleMoveForward(stepInfo?.formKey, row.original);
    }
  };

  const filteredData = connectors.filter((connector) =>
    connector.attributes.name.toLowerCase().includes(searchTerm.toLowerCase()),
  );

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        {isLoading ? (
          <Loader />
        ) : (
          <Box display='flex' flexDirection='column' gap={4}>
            <SearchBar
              placeholder='Search by name'
              borderColor='gray.400'
              setSearchTerm={setSearchTerm}
            />
            <Box border='1px' borderColor='gray.400' borderRadius='lg' overflowX='scroll'>
              <DataTable
                data={filteredData}
                columns={ConnectorsListColumns}
                onRowClick={(row) => handleOnRowClick(row)}
              />
            </Box>
          </Box>
        )}
      </ContentContainer>
    </Box>
  );
};

export default SelectModelSourceForm;
