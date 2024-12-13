<<<<<<< HEAD
import { useQuery } from '@tanstack/react-query';
import { Box } from '@chakra-ui/react';
=======
import { Box, TabList } from '@chakra-ui/react';
>>>>>>> 87701c19 (feat(CE): added pagination to connector, models and syncs pages)
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
<<<<<<< HEAD
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
=======
import TabItem from '@/components/TabItem';
import { useState } from 'react';
import TabsWrapper from '@/components/TabsWrapper';
import { SourceTypes } from '../../types';
import NoAccess from '@/enterprise/views/NoAccess';
import Pagination from '@/components/EnhancedPagination/Pagination';
import { useSearchParams } from 'react-router-dom';
import useQueryWrapper from '@/hooks/useQueryWrapper';

const SourcesList = (): JSX.Element | null => {
  const showToast = useCustomToast();
  const navigate = useProtectedNavigate();
  const [searchParams, setSearchParams] = useSearchParams();

  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const activeRole = useRoleDataStore((state) => state.activeRole);

  const pageId = searchParams.get('page');

  const onPageSelect = (page: number) => {
    setSearchParams({ page: page.toString() });
  };

  const [activeSourceType, setActiveSourceType] = useState<SourceTypes>(SourceTypes.AI_ML);

  const { data, isLoading } = useQueryWrapper(
    [...SOURCES_LIST_QUERY_KEY, activeWorkspaceId, activeSourceType, pageId],
    () =>
      getUserConnectors(
        'Source',
        activeSourceType === SourceTypes.AI_ML ? 'ai_ml' : 'data',
        pageId ? parseInt(pageId) : 1,
      ),
    {
      refetchOnMount: true,
      refetchOnWindowFocus: false,
      enabled: activeWorkspaceId > 0,
    },
  );
>>>>>>> 87701c19 (feat(CE): added pagination to connector, models and syncs pages)

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
<<<<<<< HEAD
        <Box border='1px' borderColor='gray.400' borderRadius={'lg'} overflowX='scroll'>
          <DataTable
            data={data?.data}
            columns={ConnectorsListColumns}
            onRowClick={(row) => navigate(`/setup/sources/${row?.original?.id}`)}
          />
=======
        <Box display='flex' flexDirection='column' gap='20px'>
          <TabsWrapper>
            <TabList gap='8px'>
              <TabItem text='AI/ML Sources' action={() => setActiveSourceType(SourceTypes.AI_ML)} />
              <TabItem
                text={SourceTypes.DATA_SOURCE}
                action={() => setActiveSourceType(SourceTypes.DATA_SOURCE)}
              />
            </TabList>
          </TabsWrapper>
          {isLoading || activeRole === null ? (
            <Loader />
          ) : !data || !data.data || data?.data?.length === 0 ? (
            <NoConnectors connectorType='source' sourceType={activeSourceType} />
          ) : (
            <Box border='1px' borderColor='gray.400' borderRadius={'lg'} overflowX='scroll'>
              <DataTable
                data={data?.data}
                columns={ConnectorsListColumns}
                onRowClick={(row) =>
                  navigate({
                    to: `/setup/sources/${activeSourceType}/${row?.original?.id}`,
                    location: 'connector',
                    action: UserActions.Update,
                  })
                }
              />
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
>>>>>>> 87701c19 (feat(CE): added pagination to connector, models and syncs pages)
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default SourcesList;
