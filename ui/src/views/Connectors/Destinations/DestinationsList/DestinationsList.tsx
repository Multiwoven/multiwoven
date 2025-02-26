import { Box } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';
import TopBar from '@/components/TopBar';

import ContentContainer from '@/components/ContentContainer';
import { useQuery } from '@tanstack/react-query';
import { DESTINATIONS_LIST_QUERY_KEY } from '../../constant';
import { getUserConnectors } from '@/services/connectors';
import NoConnectors from '../../NoConnectors';
import Loader from '@/components/Loader';
import { useStore } from '@/stores';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast/index';
import titleCase from '@/utils/TitleCase';
import DataTable from '@/components/DataTable';
import { ConnectorsListColumns } from '@/views/Connectors/ConnectorsListColumns/ConnectorsListColumns';
import { useNavigate } from 'react-router-dom';

const DestinationsList = (): JSX.Element | null => {
  const showToast = useCustomToast();
  const navigate = useNavigate();

  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const { data, isLoading } = useQuery({
    queryKey: [...DESTINATIONS_LIST_QUERY_KEY, activeWorkspaceId],
    queryFn: () => getUserConnectors('destination'),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: activeWorkspaceId > 0,
  });

  if (isLoading && !data) return <Loader />;

  if (data?.data?.length === 0 || !data) return <NoConnectors connectorType='destination' />;

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
    return <NoConnectors connectorType='destination' />;
  }

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
        <Box border='1px' borderColor='gray.400' borderRadius={'lg'} overflowX='scroll'>
          <DataTable
            data={data?.data}
            columns={ConnectorsListColumns}
            onRowClick={(row) => navigate(`/setup/destinations/${row?.original?.id}`)}
          />
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default DestinationsList;
