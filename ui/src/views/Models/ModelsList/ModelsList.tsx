import ContentContainer from '@/components/ContentContainer';
import TopBar from '@/components/TopBar';
import { Box } from '@chakra-ui/react';
import { FiPlus } from 'react-icons/fi';
import { useQuery } from '@tanstack/react-query';
import { AllDataModels, getAllModels, GetAllModelsResponse } from '@/services/models';
import Loader from '@/components/Loader';
import NoModels from '@/views/Models/NoModels';
import { useStore } from '@/stores';
import DataTable from '@/components/DataTable';
import { Row } from '@tanstack/react-table';
import { useNavigate } from 'react-router-dom';
import ModelsListTable from '@/views/Models/ModelsList/ModelsListTable';

const ModelsList = (): JSX.Element | null => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const navigate = useNavigate();

  const handleOnRowClick = (row: Row<GetAllModelsResponse>) => {
    navigate(`/define/models/${row.original.id}`);
  };

  const { data, isLoading } = useQuery({
    queryKey: ['models', activeWorkspaceId, 'data'],
    queryFn: () => getAllModels({ type: AllDataModels }),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: activeWorkspaceId > 0,
  });

  return (
    <Box width='100%' display='flex' flexDirection='column' alignItems='center' height='100%'>
      <ContentContainer>
        <TopBar
          name={'Models'}
          ctaName='Add Model'
          ctaIcon={<FiPlus color='gray.100' />}
          ctaButtonVariant='solid'
          onCtaClicked={() => navigate('new')}
          isCtaVisible
        />

        {isLoading ? (
          <Loader />
        ) : data?.data && data.data.length > 0 ? (
          <Box border='1px' borderColor='gray.400' borderRadius='lg' overflowX='scroll' mt={'20px'}>
            <DataTable columns={ModelsListTable} data={data.data} onRowClick={handleOnRowClick} />
          </Box>
        ) : (
          <Box h='85%'>
            <NoModels />
          </Box>
        )}
      </ContentContainer>
    </Box>
  );
};

export default ModelsList;
