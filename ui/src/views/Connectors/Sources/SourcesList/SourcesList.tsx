import { useQuery } from '@tanstack/react-query';
import { Box } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';
import TopBar from '@/components/TopBar';
import { SOURCES_LIST_QUERY_KEY } from '@/views/Connectors/constant';
import { getUserConnectors } from '@/services/connectors';
import ContentContainer from '@/components/ContentContainer';
import Loader from '@/components/Loader';
import NoConnectors from '@/views/Connectors/NoConnectors';
import { CustomToastStatus } from '@/components/Toast/index';
import titleCase from '@/utils/TitleCase';
import { ConnectorsListColumns } from '@/views/Connectors/ConnectorsListColumns/ConnectorsListColumns';
import DataTable from '@/components/DataTable';
import { useNavigate } from 'react-router-dom';
import useCustomToast from '@/hooks/useCustomToast';

const SourcesList = (): JSX.Element | null => {
  const showToast = useCustomToast();
  const navigate = useNavigate();
  const { data, isLoading } = useQuery({
    queryKey: SOURCES_LIST_QUERY_KEY,
    queryFn: () => getUserConnectors('Source'),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  if (isLoading) return <Loader />;

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
        <Box border='1px' borderColor='gray.400' borderRadius={'lg'} overflowX='scroll'>
          <DataTable
            data={data?.data}
            columns={ConnectorsListColumns}
            onRowClick={(row) => navigate(`/setup/sources/${row?.original?.id}`)}
          />
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default SourcesList;
