import { useEffect, useMemo } from 'react';
import { useParams } from 'react-router-dom';
import { Box, Image, Tabs, Text } from '@chakra-ui/react';

import { getSyncRecords } from '@/services/syncs';

import Loader from '@/components/Loader';
import ContentContainer from '@/components/ContentContainer';

import SyncRunEmptyImage from '@/assets/images/empty-state-illustration.svg';

import { SyncRecordsTopBar } from './SyncRecordsTopBar';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';
import { SyncRecordStatus } from '../types';
import { FilterTabs } from './FilterTabs';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import { ApiResponse } from '@/services/common';
import { SyncRecordResponse } from '@/views/Activate/Syncs/types';

import DataTable from '@/components/DataTable';
import { SyncRecordsColumns, useDynamicSyncColumns } from './SyncRecordsColumns';
import Pagination from '@/components/EnhancedPagination';
import useFilters from '@/hooks/useFilters';

const SyncRecords = (): JSX.Element => {
  const { filters, updateFilters } = useFilters({ page: '1', status: 'success' });
  const { syncId, syncRunId } = useParams();
  const toast = useCustomToast();

  const {
    data: filteredSyncRunRecords,
    isLoading: isFilteredSyncRecordsLoading,
    isError: isFilteredSyncRecordsError,
  } = useQueryWrapper<ApiResponse<Array<SyncRecordResponse>>, Error>(
    ['activate', 'sync-records', syncRunId, filters.page, filters.status],
    () =>
      getSyncRecords(
        syncId as string,
        syncRunId as string,
        filters.page,
        true,
        filters.status ?? 'success',
      ),
    {
      refetchOnMount: false,
      refetchOnWindowFocus: false,
    },
  );

  const data = filteredSyncRunRecords?.data;

  const dynamicSyncColumns = useDynamicSyncColumns(data ? data : []);
  const allColumns = useMemo(
    () => [...SyncRecordsColumns, ...dynamicSyncColumns],
    [SyncRecordsColumns, dynamicSyncColumns],
  );

  useEffect(() => {
    if (isFilteredSyncRecordsError) {
      toast({
        title: 'Error',
        description: 'There was an issue fetching the sync records.',
        status: CustomToastStatus.Error,
        duration: 9000,
        isClosable: true,
        position: 'bottom-right',
      });
    }
  }, [isFilteredSyncRecordsError, toast]);

  const handleStatusTabChange = (status: SyncRecordStatus) => {
    updateFilters({ page: '1', status });
  };

  return (
    <ContentContainer>
      {syncId && syncRunId ? <SyncRecordsTopBar syncId={syncId} syncRunId={syncRunId} /> : <></>}
      <Tabs
        size='md'
        variant='indicator'
        index={filters.status === SyncRecordStatus.success.toString() ? 0 : 1}
        background='gray.300'
        padding='4px'
        borderRadius='8px'
        borderStyle='solid'
        borderWidth='1px'
        borderColor='gray.400'
        width='fit-content'
        height='fit'
      >
        <FilterTabs setFilter={handleStatusTabChange} />
      </Tabs>
      {isFilteredSyncRecordsLoading ? (
        <Loader />
      ) : (
        <Box width='100%' pt={'20px'}>
          {data?.length === 0 || !data ? (
            <Box
              display='flex'
              w='fit-content'
              mx='auto'
              flexDirection='column'
              gap='20px'
              mt='10%'
            >
              <Image src={SyncRunEmptyImage} w='175px' h='132px' />
              <Text fontSize='xl' mx='auto' color='gray.600' fontWeight='semibold'>
                No rows found
              </Text>
            </Box>
          ) : (
            <Box>
              <Box border='1px' borderColor='gray.400' borderRadius='lg' overflowX='scroll'>
                <DataTable data={data} columns={allColumns} />
              </Box>
              <Box display='flex' justifyContent='center' pt='20px'>
                {filteredSyncRunRecords.links ? (
                  <Pagination
                    links={filteredSyncRunRecords?.links}
                    currentPage={filters.page ? Number(filters.page) : 1}
                    handlePageChange={(page) =>
                      updateFilters({ ...filters, page: page.toString() })
                    }
                  />
                ) : (
                  <>Pagination unavailable.</>
                )}
              </Box>
            </Box>
          )}
        </Box>
      )}
    </ContentContainer>
  );
};

export default SyncRecords;
