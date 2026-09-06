import ContentContainer from '@/components/ContentContainer';
import Loader from '@/components/Loader';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import { getUserConnectors } from '@/services/connectors';
import DestinationsTable from '@/views/Connectors/Destinations/DestinationsList/DestinationsTable';
import NoConnectors from '@/views/Connectors/NoConnectors';
import { DESTINATIONS_LIST_QUERY_KEY } from '@/views/Connectors/constant';
import { Box } from '@chakra-ui/react';
import { useContext, Dispatch, SetStateAction } from 'react';
import { Stream, FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';
import FormFooter from '@/components/FormFooter';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import { ConnectorListResponse } from '@/views/Connectors/types';

const SelectDestination = ({
  setSelectedStream,
  setConfiguration,
}: {
  setSelectedStream: Dispatch<SetStateAction<Stream | null>>;
  setConfiguration: Dispatch<SetStateAction<FieldMapType[] | null>>;
}): JSX.Element => {
  const { stepInfo, handleMoveForward } = useContext(SteppedFormContext);

  const handleOnRowClick = (data: Record<'connector', unknown>) => {
    // to reset the state of config sync screen
    setSelectedStream(null);
    setConfiguration(null);

    handleMoveForward(stepInfo?.formKey as string, data?.connector);
  };

  const { data, isLoading } = useQueryWrapper<ConnectorListResponse, Error>(
    DESTINATIONS_LIST_QUERY_KEY,
    () => getUserConnectors('destination'),
    {
      refetchOnMount: false,
      refetchOnWindowFocus: false,
    },
  );

  if (isLoading && !data) return <Loader />;

  if (data?.data.length === 0) return <NoConnectors connectorType='destination' />;

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        {isLoading || !data ? (
          <Loader />
        ) : (
          <>
<<<<<<< HEAD
            <DestinationsTable
              handleOnRowClick={(data) => handleOnRowClick(data)}
              destinationData={data}
              isLoading={isLoading}
            />
=======
            <Box display='flex' flexDirection='column' gap={4}>
              <SearchBar
                placeholder='Search by name'
                borderColor='gray.400'
                setSearchTerm={setSearchTerm}
              />
              <Box border='1px' borderColor='gray.400' borderRadius='lg' overflowX='scroll'>
                <DataTable
                  columns={ConnectorsListColumns}
                  data={filteredData || []}
                  onRowClick={handleOnRowClick}
                />
              </Box>
            </Box>
>>>>>>> dd10f24d (fix(CE): remove show search bar prop)
            <FormFooter ctaName='Continue' ctaType='submit' isBackRequired />
          </>
        )}
      </ContentContainer>
    </Box>
  );
};

export default SelectDestination;
