import { Box } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';
import TopBar from '@/components/TopBar';
import { useNavigate } from 'react-router-dom';

import ContentContainer from '@/components/ContentContainer';
import DestinationsTable from './DestinationsTable';
import { useQuery } from '@tanstack/react-query';
import { DESTINATIONS_LIST_QUERY_KEY } from '../../constant';
import { getUserConnectors } from '@/services/connectors';
import NoConnectors from '../../NoConnectors';
import Loader from '@/components/Loader';

const DestinationsList = (): JSX.Element | null => {
  const navigate = useNavigate();

  const { data, isLoading } = useQuery({
    queryKey: DESTINATIONS_LIST_QUERY_KEY,
    queryFn: () => getUserConnectors('destination'),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  if (isLoading && !data) return <Loader />;

  if (data?.data.length === 0) return <NoConnectors connectorType='destination' />;

  return (
    <Box width='100%' display='flex' flexDirection='column' alignItems='center'>
      <ContentContainer>
        <TopBar
          name='Destinations'
          ctaName='Add Destination'
          ctaIcon={<FiPlus color='gray.100' />}
          onCtaClicked={() => navigate('new')}
          ctaButtonVariant='solid'
          ctaButtonWidth='fit'
          ctaButtonHeight='40px'
          isCtaVisible
        />
        {isLoading || !data ? (
          <Loader />
        ) : (
          <DestinationsTable
            handleOnRowClick={(row) => navigate(`/setup/destinations/${row?.id}`)}
            destinationData={data}
            isLoading={isLoading}
          />
        )}
      </ContentContainer>
    </Box>
  );
};

export default DestinationsList;
