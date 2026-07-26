import { Box } from '@chakra-ui/react';
import ContentContainer from '@/components/ContentContainer';
import TopBar from '@/components/TopBar';

import { useAPIErrorsToast } from '@/hooks/useErrorToast';
import DataTable from '@/components/DataTable';
import Loader from '@/components/Loader';
import useProtectedNavigate from '@/enterprise/hooks/useProtectedNavigate';
import { UserActions } from '@/enterprise/types';
import Pagination from '@/components/EnhancedPagination';
import useFilters from '@/hooks/useFilters';
import useDataAppQueries from '@/enterprise/hooks/queries/useDataAppQueries';
import NoAssistants from './NoAssistants';
import { RENDERING_OPTION_TYPE } from '../../DataApps/DataAppsForm/types';
import { AssistantColumns } from './AssistantColumns';
import { DataAppsResponse } from '@/enterprise/services/types';

const AssistantsList = () => {
  const { useGetDataApps } = useDataAppQueries();
  const { filters, updateFilters } = useFilters({
    page: '1',
    rendering_type: 'assistant',
  });
  const navigate = useProtectedNavigate();
  const apiErrorToast = useAPIErrorsToast();

  const { data: dataApps, isLoading: isDataAppsFetching } = useGetDataApps(filters);

  const onPageSelect = (page: number) => {
    updateFilters({
      page: page.toString(),
      rendering_type: 'assistant',
    });
  };

  if (dataApps?.errors) {
    apiErrorToast(dataApps.errors);
    return;
  }

  const assistantsDataApps = dataApps?.data?.filter(
    (app) => app.attributes.rendering_type === RENDERING_OPTION_TYPE.ASSISTANT,
  );

  if (isDataAppsFetching) {
    return <Loader />;
  }

  return (
    <Box width='100%' display='flex' flexDirection='column' alignItems='center'>
      <ContentContainer>
        <TopBar
          name={'Chat Assistants'}
          description='Access and interact with your standalone chat assistants created using AI workflows and Data Apps.'
        />
        {assistantsDataApps?.length === 0 ? (
          <NoAssistants />
        ) : (
          <Box>
            <Box border='1px' borderColor='gray.400' borderRadius={'lg'} overflowX='scroll'>
              <DataTable
                data={assistantsDataApps || []}
                columns={AssistantColumns}
                getRowProps={(row) => {
                  const app = row.original as DataAppsResponse;
                  const title =
                    app.attributes?.visual_components?.[0]?.properties?.card_title ?? '';
                  return {
                    'data-testid': `assistant-list-row-${app.id}`,
                    'data-assistant-card-title': title,
                  };
                }}
                onRowClick={(row) =>
                  navigate({
                    to: `${row.original.id}`,
                    location: 'data_app',
                    action: UserActions.Read,
                  })
                }
              />
            </Box>
            <Box display='flex' justifyContent='center' pt='20px'>
              {dataApps?.links && (
                <Pagination
                  links={dataApps?.links}
                  currentPage={filters.page ? Number(filters.page) : 1}
                  handlePageChange={onPageSelect}
                />
              )}
            </Box>
          </Box>
        )}
      </ContentContainer>
    </Box>
  );
};

export default AssistantsList;
