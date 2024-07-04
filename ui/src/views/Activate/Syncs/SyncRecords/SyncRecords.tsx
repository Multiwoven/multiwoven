import { useEffect, useMemo, useState } from 'react';
import { useParams, useSearchParams } from 'react-router-dom';
import { Box, Image, Tabs, Text } from '@chakra-ui/react';

import { getSyncRecords } from '@/services/syncs';

import Loader from '@/components/Loader';
import ContentContainer from '@/components/ContentContainer';

import Pagination from '@/components/Pagination';
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

const SyncRecords = (): JSX.Element => {
  const [searchParams, setSearchParams] = useSearchParams();
  const { syncId, syncRunId } = useParams();
  const toast = useCustomToast();

  const pageId = searchParams.get('page');
  const [currentPage, setCurrentPage] = useState(Number(pageId) || 1);

  const [currentFilter, setCurrentFilter] = useState<SyncRecordStatus>(SyncRecordStatus.success);

  const {
    data: syncRunRecords,
    isLoading: isSyncRecordsLoading,
    isError: isSyncRecordsError,
  } = useQueryWrapper<ApiResponse<Array<SyncRecordResponse>>, Error>(
    ['activate', 'sync-records', syncRunId, currentPage],
    () => getSyncRecords(syncId as string, syncRunId as string, currentPage.toString()),
    {
      refetchOnMount: true,
      refetchOnWindowFocus: false,
    },
  );

  const data = useMemo(
    () => syncRunRecords?.data?.filter?.((record) => record.attributes.status === currentFilter),
    [syncRunRecords, currentFilter],
  );

  const dynamicSyncColumns = useDynamicSyncColumns(data ? data : []);
  const allColumns = useMemo(
    () => [...SyncRecordsColumns, ...dynamicSyncColumns],
    [SyncRecordsColumns, dynamicSyncColumns],
  );

  useEffect(() => {
    setSearchParams({ page: currentPage.toString() });
  }, [currentPage, setSearchParams]);

  useEffect(() => {
    if (isSyncRecordsError) {
      toast({
        title: 'Error',
        description: 'There was an issue fetching the sync records.',
        status: CustomToastStatus.Error,
        duration: 9000,
        isClosable: true,
        position: 'bottom-right',
      });
    }
  }, [isSyncRecordsError, toast]);

  const handleNextPage = () => {
    if (syncRunRecords?.links?.next) {
      setCurrentPage((prevPage) => prevPage + 1);
    }
  };

  const handlePrevPage = () => {
    if (syncRunRecords?.links?.prev) {
      setCurrentPage((prevPage) => Math.max(prevPage - 1, 1));
    }
  };

  return (
    <ContentContainer>
      {syncId && syncRunId ? <SyncRecordsTopBar syncId={syncId} syncRunId={syncRunId} /> : <></>}
      <Tabs
        size='md'
        variant='indicator'
        onChange={(index) =>
          setCurrentFilter(index === 0 ? SyncRecordStatus.success : SyncRecordStatus.failed)
        }
        background='gray.300'
        padding='4px'
        borderRadius='8px'
        borderStyle='solid'
        borderWidth='1px'
        borderColor='gray.400'
        width='fit-content'
        height='fit'
      >
        <FilterTabs setFilter={setCurrentFilter} syncRunRecords={syncRunRecords} />
      </Tabs>
      {isSyncRecordsLoading ? (
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
              <Box display='flex' flexDirection='row-reverse' pt='10px'>
                <Pagination
                  currentPage={currentPage}
                  isPrevPageEnabled={syncRunRecords?.links?.prev != null}
                  isNextPageEnabled={syncRunRecords?.links?.next != null}
                  handleNextPage={handleNextPage}
                  handlePrevPage={handlePrevPage}
                />
              </Box>
            </Box>
          )}
        </Box>
      )}
    </ContentContainer>
  );
};

export default SyncRecords;
