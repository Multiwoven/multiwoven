import ContentContainer from '@/components/ContentContainer';
import TopBar from '@/components/TopBar';
<<<<<<< HEAD
import { Box } from '@chakra-ui/react';
=======
import { Box, TabList } from '@chakra-ui/react';
>>>>>>> 87701c19 (feat(CE): added pagination to connector, models and syncs pages)
import { FiPlus } from 'react-icons/fi';
import { useQuery } from '@tanstack/react-query';
import { getAllModels, GetAllModelsResponse } from '@/services/models';
import Loader from '@/components/Loader';
import NoModels from '@/views/Models/NoModels';
import { useStore } from '@/stores';
import DataTable from '@/components/DataTable';
import { Row } from '@tanstack/react-table';
<<<<<<< HEAD
import { useNavigate } from 'react-router-dom';
import ModelsListTable from '@/views/Models/ModelsList/ModelsListTable';
=======
import NoAccess from '@/enterprise/views/NoAccess';
import Pagination from '@/components/EnhancedPagination/Pagination';
import { useSearchParams } from 'react-router-dom';
import { useAPIErrorsToast } from '@/hooks/useErrorToast';
import TabsWrapper from '@/components/TabsWrapper';
>>>>>>> 87701c19 (feat(CE): added pagination to connector, models and syncs pages)

const ModelsList = (): JSX.Element | null => {
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useProtectedNavigate();
  const apiErrors = useAPIErrorsToast();

  const activeWorkspaceId = useStore((state) => state.workspaceId);
<<<<<<< HEAD
  const navigate = useNavigate();
=======
  const activeRole = useRoleDataStore((state) => state.activeRole);

  const pageId = searchParams.get('page');

  const onPageSelect = (page: number) => {
    setSearchParams({ page: page.toString() });
  };
>>>>>>> 87701c19 (feat(CE): added pagination to connector, models and syncs pages)

  const handleOnRowClick = (row: Row<GetAllModelsResponse>) => {
    navigate(`/define/models/${row.original.id}`);
  };

  const { data, isLoading } = useQuery({
<<<<<<< HEAD
    queryKey: ['models', activeWorkspaceId, 'data'],
    queryFn: () => getAllModels({ type: 'data' }),
=======
    queryKey: ['models', activeWorkspaceId, currentTab, pageId],
    queryFn: () =>
      getAllModels({
        type: currentTab,
        page: pageId ? Number(pageId) : 1,
      }),
>>>>>>> 87701c19 (feat(CE): added pagination to connector, models and syncs pages)
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: activeWorkspaceId > 0,
  });

<<<<<<< HEAD
=======
  if (data?.errors) {
    apiErrors(data.errors);
  }

  if (!activeRole) return <NoAccess />;

  const hasPermission = hasActionPermission(activeRole, 'model', UserActions.Create);

>>>>>>> 87701c19 (feat(CE): added pagination to connector, models and syncs pages)
  return (
    <Box width='100%' display='flex' flexDirection='column' alignItems='center'>
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
        <Box display='flex' flexDirection='column' gap='20px'>
          <TabsWrapper>
            <TabList gap='8px'>
              <TabItem text='AI/ML Models' action={() => setCurrentTab('ai_ml')} />
              <TabItem text='Data Models' action={() => setCurrentTab('data')} />
            </TabList>
          </TabsWrapper>

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
                currentPage={pageId ? Number(pageId) : 1}
                handlePageChange={onPageSelect}
              />
            </Box>
          )}
        </Box>
>>>>>>> 87701c19 (feat(CE): added pagination to connector, models and syncs pages)
      </ContentContainer>
    </Box>
  );
};

export default ModelsList;
