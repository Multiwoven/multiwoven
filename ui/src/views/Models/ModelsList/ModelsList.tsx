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
<<<<<<< HEAD
import { useNavigate } from 'react-router-dom';
import ModelsListTable from '@/views/Models/ModelsList/ModelsListTable';

const ModelsList = (): JSX.Element | null => {
=======
import NoAccess from '@/enterprise/views/NoAccess';
import Pagination from '@/components/EnhancedPagination/Pagination';
import { useAPIErrorsToast } from '@/hooks/useErrorToast';
import TabsWrapper from '@/components/TabsWrapper';
import useFilters from '@/hooks/useFilters';

const ModelsList = (): JSX.Element | null => {
  const { filters, updateFilters } = useFilters({ page: '1' });
  const navigate = useProtectedNavigate();
  const apiErrors = useAPIErrorsToast();

>>>>>>> 9bfb0995 (refactor(CE): lists filtering and query params building (#860))
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const navigate = useNavigate();

<<<<<<< HEAD
  const handleOnRowClick = (row: Row<GetAllModelsResponse>) => {
    navigate(`/define/models/${row.original.id}`);
  };

  const { data, isLoading } = useQuery({
    queryKey: ['models', activeWorkspaceId, 'data'],
    queryFn: () => getAllModels({ type: AllDataModels }),
=======
  const onPageSelect = (page: number) => {
    updateFilters({ page: page.toString() });
  };

  const [currentTab, setCurrentTab] = useState<string>('ai_ml');

  const handleOnRowClick = (row: Row<GetAllModelsResponse>, modelQueryType: string) => {
    navigate({
      to: modelQueryType === 'ai_ml' ? `/define/models/ai/${row.original.id}` : row?.original.id,
      location: 'model',
      action: UserActions.Read,
    });
  };

  const { data, isLoading } = useQuery({
    queryKey: ['models', activeWorkspaceId, currentTab, filters.page ?? '1'],
    queryFn: () =>
      getAllModels({
        type: currentTab === 'ai_ml' ? 'ai_ml' : AllDataModels,
        page: filters.page ? Number(filters.page) : 1,
      }),
>>>>>>> 9bfb0995 (refactor(CE): lists filtering and query params building (#860))
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

<<<<<<< HEAD
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
=======
          {isLoading ? (
            <Loader />
          ) : data?.data && data.data.length > 0 ? (
            <Box border='1px' borderColor='gray.400' borderRadius='lg' overflowX='scroll'>
              <DataTable
                columns={currentTab === 'ai_ml' ? AIModelsListTable : ModelsListTable}
                data={data.data}
                onRowClick={(row) => handleOnRowClick(row, currentTab)}
              />
            </Box>
          ) : (
            <Box h='70vh'>
              <NoModels isAiModel={currentTab === 'ai_ml'} />
            </Box>
          )}
          {data?.data && data.data.length > 0 && data.links && (
            <Box display='flex' justifyContent='center'>
              <Pagination
                links={data?.links}
                currentPage={filters.page ? Number(filters.page) : 1}
                handlePageChange={onPageSelect}
              />
            </Box>
          )}
        </Box>
>>>>>>> 9bfb0995 (refactor(CE): lists filtering and query params building (#860))
      </ContentContainer>
    </Box>
  );
};

export default ModelsList;
