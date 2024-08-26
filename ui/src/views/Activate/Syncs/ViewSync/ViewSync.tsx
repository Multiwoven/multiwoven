<<<<<<< HEAD
=======
import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { Box, Divider, Switch, TabIndicator, TabList, Tabs, Text } from '@chakra-ui/react';
import { FiCheckCircle } from 'react-icons/fi';
import moment from 'moment';

>>>>>>> 38bcb066 (feat(CE): Enable and Disable sync via UI)
import TopBar from '@/components/TopBar';
import { getSyncById } from '@/services/syncs';
import { Box, Divider, TabIndicator, TabList, Tabs, Text } from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import { useParams } from 'react-router-dom';
import MappedInfo from '../EditSync/MappedInfo';
import moment from 'moment';
import SyncActions from '../EditSync/SyncActions';
import ContentContainer from '@/components/ContentContainer';
import { useEffect, useState } from 'react';
import EditSync from '../EditSync';
import TabItem from '@/components/TabItem';
import Loader from '@/components/Loader';
import SyncRuns from '../SyncRuns';
import { Step } from '@/components/Breadcrumbs/types';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';
import { useStore } from '@/stores';
import { useSyncStore } from '@/stores/useSyncStore';

import { changeSyncStatus } from '@/services/syncs';

import { useAPIErrorsToast, useErrorToast } from '@/hooks/useErrorToast';

enum SyncTabs {
  Tab1 = 'runs',
  Tab2 = 'config',
}

const ViewSync = (): JSX.Element => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const setSelectedSync = useSyncStore((state) => state.setSelectedSync);

<<<<<<< HEAD
  const [syncTab, setSyncTab] = useState<SyncTabs>(SyncTabs.Tab1);
=======
  const [syncTab, setSyncTab] = useState<SyncTabs>(SyncTabs.Runs);
  const [syncStatus, setSyncStatus] = useState<boolean>(false);

>>>>>>> 38bcb066 (feat(CE): Enable and Disable sync via UI)
  const { syncId } = useParams();

  const toast = useCustomToast();
  const errorToast = useErrorToast();
  const apiError = useAPIErrorsToast();

  const {
    data: syncFetchResponse,
    isLoading,
    isError,
  } = useQuery({
    queryKey: ['sync', syncId, activeWorkspaceId],
    queryFn: () => getSyncById(syncId as string),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
    enabled: !!syncId && activeWorkspaceId > 0,
  });

  const syncData = syncFetchResponse?.data?.attributes;

  const EDIT_SYNC_FORM_STEPS: Step[] = [
    {
      name: 'Syncs',
      url: '/activate/syncs',
    },
    {
      name: syncData?.name || 'Sync ' + syncId,
      url: '',
    },
  ];

  const handleSyncStatusChange = async () => {
    try {
      const syncChangeResponse = await changeSyncStatus(syncId as string, { enable: !syncStatus });
      if (syncChangeResponse.data) {
        setSyncStatus(!syncStatus);
        toast({
          status: CustomToastStatus.Success,
          title: `Sync ${syncStatus ? 'disabled' : 'enabled'} successfully`,
          position: 'bottom-right',
          isClosable: true,
        });
      }
      if (syncChangeResponse.errors) {
        apiError(syncChangeResponse.errors);
      }
    } catch (error) {
      errorToast("Couldn't change sync status. Please try again.", true, error, true);
    }
  };

  useEffect(() => {
    if (isError) {
      toast({
        status: CustomToastStatus.Error,
        title: 'Error!',
        description: 'Something went wrong',
        position: 'bottom-right',
        isClosable: true,
      });
    }
  }, [isError]);

  useEffect(() => {
<<<<<<< HEAD
    setSelectedSync({
      syncName: syncData?.name,
      sourceName: syncData?.model.connector.name,
      sourceIcon: syncData?.model.connector.icon,
      destinationName: syncData?.destination.name,
      destinationIcon: syncData?.destination.icon,
    });
  }, [syncData]);
=======
    if (syncData) {
      setSelectedSync({
        syncName: syncData.name,
        sourceName: syncData.model.connector.name,
        sourceIcon: syncData.model.connector.icon,
        destinationName: syncData.destination.name,
        destinationIcon: syncData.destination.icon,
      });
      setSyncStatus(syncData.status === 'disabled' ? false : true);
    }
  }, [syncData, setSelectedSync]);

  const EDIT_SYNC_FORM_STEPS: Step[] = [
    { name: 'Syncs', url: '/activate/syncs' },
    { name: syncData?.name || `Sync ${syncId}`, url: '' },
  ];
>>>>>>> 38bcb066 (feat(CE): Enable and Disable sync via UI)

  return (
    <ContentContainer>
      {isLoading || !syncData ? <Loader /> : null}
      <TopBar
        name='Sync'
        breadcrumbSteps={EDIT_SYNC_FORM_STEPS}
        extra={
          syncData?.model ? (
            <Box display='flex' alignItems='center'>
              <MappedInfo
                source={{
                  name: syncData?.model.connector.name,
                  icon: syncData?.model.connector.icon,
                }}
                destination={{
                  name: syncData?.destination.name,
                  icon: syncData?.destination.icon,
                }}
              />
              <Divider
                orientation='vertical'
                height='24px'
                borderColor='gray.500'
                opacity='1'
                marginX='13px'
              />
              <Text size='sm' fontWeight='medium'>
                Sync ID :{' '}
              </Text>
              <Text size='sm' fontWeight='semibold'>
                {syncId}
              </Text>
              <Divider
                orientation='vertical'
                height='24px'
                borderColor='gray.500'
                opacity='1'
                marginX='13px'
              />
              <Text size='sm' fontWeight='medium'>
                Last updated :{' '}
              </Text>
              <Text size='sm' fontWeight='semibold'>
                {moment(syncData.updated_at).format('DD/MM/YYYY')}
              </Text>
              <SyncActions />
            </Box>
          ) : null
        }
      />
<<<<<<< HEAD
      <Tabs
        size='md'
        variant='indicator'
        background='gray.300'
        padding='4px'
        borderRadius='8px'
        borderStyle='solid'
        borderWidth='1px'
        borderColor='gray.400'
        width='fit-content'
        height='fit'
      >
        <TabList gap='8px'>
          <TabItem text='Sync Runs' action={() => setSyncTab(SyncTabs.Tab1)} />
          <TabItem text='Configuration' action={() => setSyncTab(SyncTabs.Tab2)} />
        </TabList>
        <TabIndicator />
      </Tabs>
      {syncTab === SyncTabs.Tab1 ? <SyncRuns /> : <EditSync />}
=======
      <Box display='flex' justifyContent='space-between'>
        <Tabs
          size='md'
          variant='indicator'
          background='gray.300'
          padding='4px'
          borderRadius='8px'
          borderStyle='solid'
          borderWidth='1px'
          borderColor='gray.400'
          width='fit-content'
        >
          <TabList gap='8px'>
            <RoleAccess location='sync_run' type='item' action={UserActions.Read}>
              <TabItem text='Sync Runs' action={() => setSyncTab(SyncTabs.Runs)} />
            </RoleAccess>
            <RoleAccess location='sync' type='item' action={UserActions.Update}>
              <TabItem text='Configuration' action={() => setSyncTab(SyncTabs.Config)} />
            </RoleAccess>
          </TabList>
          <TabIndicator />
        </Tabs>
        {syncTab === SyncTabs.Config && (
          <Box display='flex' flexDir='row' gap='12px'>
            <RoleAccess location='sync' type='item' action={UserActions.Update}>
              <Box
                h='100%'
                w='fit-content'
                border='1px'
                borderRadius='6px'
                borderColor='gray.500'
                display='flex'
                flexDir='row'
                gap='8px'
                alignItems='center'
                py='6px'
                pr='6px'
                pl='12px'
              >
                <Text size='xs' fontWeight='bold' textColor='gray.600' letterSpacing='2.4px'>
                  SYNC {syncStatus ? 'ENABLED' : 'DISABLED'}
                </Text>
                <Switch
                  isChecked={syncStatus}
                  colorScheme='brand'
                  onChange={handleSyncStatusChange}
                />
              </Box>
            </RoleAccess>
            <RoleAccess location='sync_run' type='item' action={UserActions.Create}>
              <BaseButton
                text='Test Sync'
                onClick={runTestSync}
                variant='shell'
                color='black.500'
                leftIcon={<FiCheckCircle color='black.500' />}
                isLoading={isSubmitting}
              />
            </RoleAccess>
          </Box>
        )}
      </Box>
      <SyncTabContent syncTab={syncTab} />
>>>>>>> 38bcb066 (feat(CE): Enable and Disable sync via UI)
    </ContentContainer>
  );
};

export default ViewSync;
