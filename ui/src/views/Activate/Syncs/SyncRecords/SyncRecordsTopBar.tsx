import { Step } from '@/components/Breadcrumbs/types';
import StatusTag, { StatusTagText, StatusTagVariants } from '@/components/StatusTag/StatusTag';
import { CustomToastStatus } from '@/components/Toast';
import TopBar from '@/components/TopBar';
import useCustomToast from '@/hooks/useCustomToast';
import { getSyncRunById } from '@/services/syncs';
import { Box, Divider, Text } from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import moment from 'moment';
import { useEffect } from 'react';
import { useStore } from '@/stores';
import { useSyncStore } from '@/stores/useSyncStore';
import { useAPIErrorsToast } from '@/hooks/useErrorToast';

export const SyncRecordsTopBar = ({ syncId, syncRunId }: { syncId: string; syncRunId: string }) => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const selectedSync = useSyncStore((state) => state.selectedSync);
  const apiErrorToast = useAPIErrorsToast();

  const toast = useCustomToast();

  const { data: syncRunData, isError: isSyncRunDataError } = useQuery({
    queryKey: ['activate', 'sync-run-by-id', syncId, syncRunId],
    queryFn: () => getSyncRunById(syncId || '', syncRunId || ''),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
    enabled: activeWorkspaceId > 0,
  });

  if (syncRunData?.errors && syncRunData?.errors.length > 0) {
    apiErrorToast(syncRunData.errors);
  }

  const VIEW_SYNC_RUN_RECORDS_STEPS: Step[] = [
    {
      name: 'Syncs',
      url: '/activate/syncs',
    },
    {
      name: selectedSync.syncName || 'Sync ' + syncId,
      url: '/activate/syncs/' + syncId,
    },
    {
      name: 'Run ' + syncRunId,
      url: '',
    },
  ];

  const variant = syncRunData?.data?.attributes?.status as StatusTagVariants;
  const tagText = StatusTagText[variant];

  useEffect(() => {
    if (isSyncRunDataError) {
      toast({
        status: CustomToastStatus.Error,
        title: 'Error!',
        description: 'Something went wrong',
        position: 'bottom-right',
        isClosable: true,
      });
    }
  }, [isSyncRunDataError]);

  return (
    <TopBar
      name='Sync Run'
      breadcrumbSteps={VIEW_SYNC_RUN_RECORDS_STEPS}
      extra={
        <Box display='flex' alignItems='center'>
          <StatusTag variant={variant} status={tagText} />
          <Divider
            orientation='vertical'
            height='24px'
            borderColor='gray.500'
            opacity='1'
            marginX='13px'
          />
          <Text size='sm' fontWeight='medium'>
            Run ID :{' '}
          </Text>
          <Text size='sm' fontWeight='semibold'>
            {syncRunId}
          </Text>
          <Divider
            orientation='vertical'
            height='24px'
            borderColor='gray.500'
            opacity='1'
            marginX='13px'
          />
          <Text size='sm' fontWeight='medium'>
            Start Time :{' '}
          </Text>
          <Text size='sm' fontWeight='semibold'>
            {moment(syncRunData?.data?.attributes?.started_at).format('DD/MM/YYYY HH:mm a')}
          </Text>
          <Divider
            orientation='vertical'
            height='24px'
            borderColor='gray.500'
            opacity='1'
            marginX='13px'
          />
          <Text size='sm' fontWeight='medium'>
            Duration :{' '}
          </Text>
          <Text size='sm' fontWeight='semibold'>
            {syncRunData?.data?.attributes?.duration
              ? syncRunData?.data.attributes.duration?.toPrecision(3) + ' seconds '
              : 'No Duration Available'}
          </Text>
        </Box>
      }
    />
  );
};
