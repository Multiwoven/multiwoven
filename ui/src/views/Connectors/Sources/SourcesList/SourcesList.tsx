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
<<<<<<< HEAD
import { useNavigate } from 'react-router-dom';
import useCustomToast from '@/hooks/useCustomToast';
=======
import TabItem from '@/components/TabItem';
import { useState } from 'react';
import TabsWrapper from '@/components/TabsWrapper';
import { SourceTypes } from '../../types';
import NoAccess from '@/enterprise/views/NoAccess';
import Pagination from '@/components/EnhancedPagination/Pagination';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import useFilters from '@/hooks/useFilters';
>>>>>>> 9bfb0995 (refactor(CE): lists filtering and query params building (#860))

const SourcesList = (): JSX.Element | null => {
  const { filters, updateFilters } = useFilters({ page: '1' });
  const showToast = useCustomToast();
<<<<<<< HEAD
  const navigate = useNavigate();
  const { data, isLoading } = useQuery({
    queryKey: SOURCES_LIST_QUERY_KEY,
    queryFn: () => getUserConnectors('Source'),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });
=======
  const navigate = useProtectedNavigate();
>>>>>>> 9bfb0995 (refactor(CE): lists filtering and query params building (#860))

  if (isLoading) return <Loader />;

<<<<<<< HEAD
  if (data?.data?.length === 0 || !data) return <NoConnectors connectorType='source' />;
=======
  const onPageSelect = (page: number) => {
    updateFilters({ page: page.toString() });
  };

  const [activeSourceType, setActiveSourceType] = useState<SourceTypes>(SourceTypes.AI_ML);

  const { data, isLoading } = useQueryWrapper(
    [...SOURCES_LIST_QUERY_KEY, activeWorkspaceId, activeSourceType, filters.page ?? '1'],
    () =>
      getUserConnectors(
        'Source',
        activeSourceType === SourceTypes.AI_ML ? 'ai_ml' : 'data',
        filters.page ? parseInt(filters.page) : 1,
      ),
    {
      refetchOnMount: true,
      refetchOnWindowFocus: false,
      enabled: activeWorkspaceId > 0,
    },
  );
>>>>>>> 9bfb0995 (refactor(CE): lists filtering and query params building (#860))

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
                currentPage={filters.page ? Number(filters.page) : 1}
                handlePageChange={onPageSelect}
              />
            </Box>
          )}
>>>>>>> 9bfb0995 (refactor(CE): lists filtering and query params building (#860))
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default SourcesList;
