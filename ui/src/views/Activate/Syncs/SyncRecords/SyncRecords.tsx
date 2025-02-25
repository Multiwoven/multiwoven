import { useEffect, useMemo, useState } from 'react';
import { useParams, useSearchParams } from 'react-router-dom';
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

const SyncRecords = (): JSX.Element => {
  const [searchParams, setSearchParams] = useSearchParams();
  const { syncId, syncRunId } = useParams();
  const toast = useCustomToast();

  const pageId = searchParams.get('page');
  const statusTab = searchParams.get('status');

  const [currentPage, setCurrentPage] = useState(Number(pageId) || 1);
  const [currentStatusTab, setCurrentStatusTab] = useState<SyncRecordStatus>(
    statusTab === SyncRecordStatus.failed ? SyncRecordStatus.failed : SyncRecordStatus.success,
  );

  const {
    data: filteredSyncRunRecords,
    isLoading: isFilteredSyncRecordsLoading,
    isError: isFilteredSyncRecordsError,
    refetch: refetchFilteredSyncRecords,
  } = useQueryWrapper<ApiResponse<Array<SyncRecordResponse>>, Error>(
    ['activate', 'sync-records', syncRunId, currentPage, statusTab],
    () =>
      getSyncRecords(
        syncId as string,
        syncRunId as string,
        currentPage.toString(),
        true,
        statusTab || 'success',
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
    setSearchParams({ page: currentPage.toString(), status: currentStatusTab });
  }, [currentPage, currentStatusTab, setSearchParams]);

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
    setCurrentPage(1);
    setCurrentStatusTab(status);
    refetchFilteredSyncRecords;
  };

  return (
    <ContentContainer>
      {syncId && syncRunId ? <SyncRecordsTopBar syncId={syncId} syncRunId={syncRunId} /> : <></>}
      <Tabs
        size='md'
        variant='indicator'
        onChange={(index) =>
          handleStatusTabChange(index === 0 ? SyncRecordStatus.success : SyncRecordStatus.failed)
        }
        index={currentStatusTab === SyncRecordStatus.success ? 0 : 1}
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
                {data && data.length > 0 && filteredSyncRunRecords.links ? (
                  <Pagination
                    links={filteredSyncRunRecords?.links}
                    currentPage={currentPage}
                    handlePageChange={setCurrentPage}
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
