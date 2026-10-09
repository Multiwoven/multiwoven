import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { Box, Divider, Switch, TabList, Text } from '@chakra-ui/react';
import moment from 'moment';

import TopBar from '@/components/TopBar';
import ContentContainer from '@/components/ContentContainer';
import TabItem from '@/components/TabItem';
import Loader from '@/components/Loader';
import { Step } from '@/components/Breadcrumbs/types';

import { useStore } from '@/stores';
import { useSyncStore } from '@/stores/useSyncStore';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';

import MappedInfo from '../EditSync/MappedInfo';
import SyncActions from '../EditSync/SyncActions';
import SyncRuns from '../SyncRuns';
import EditSync from '../EditSync';
import useGetSyncById from '@/hooks/syncs/useGetSyncById';
import TabsWrapper from '@/components/TabsWrapper';

import { changeSyncStatus } from '@/services/syncs';

import { useAPIErrorsToast, useErrorToast } from '@/hooks/useErrorToast';

enum SyncTabs {
  Runs = 'runs',
  Config = 'config',
}

const SyncDetails = ({ syncData, syncId }: any) => (
  <Box display='flex' alignItems='center'>
    <MappedInfo
      info={[
        {
          name: syncData.model.connector.name,
          icon: syncData.model.connector.icon,
        },
        {
          name: syncData.model.name,
          icon: syncData.model.connector.icon,
        },
        {
          name: syncData.destination.name,
          icon: syncData.destination.icon,
        },
      ]}
    />
    <Divider orientation='vertical' height='24px' borderColor='gray.500' opacity='1' mx='13px' />
    <Text size='sm' fontWeight='medium'>
      Sync ID :{' '}
    </Text>
    <Text size='sm' fontWeight='semibold'>
      {syncId}
    </Text>
    <Divider orientation='vertical' height='24px' borderColor='gray.500' opacity='1' mx='13px' />
    <Text size='sm' fontWeight='medium'>
      Last updated :{' '}
    </Text>
    <Text size='sm' fontWeight='semibold'>
      {moment(syncData.updated_at).format('DD/MM/YYYY')}
    </Text>
    <SyncActions />
  </Box>
);

const SyncTabContent = ({ syncTab }: { syncTab: SyncTabs }) => {
  return syncTab === SyncTabs.Runs ? <SyncRuns /> : <EditSync />;
};

const ViewSync = (): JSX.Element => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);
  const setSelectedSync = useSyncStore((state) => state.setSelectedSync);

  const [syncTab, setSyncTab] = useState<SyncTabs>(SyncTabs.Runs);
  const [syncStatus, setSyncStatus] = useState<boolean>(false);

  const { syncId } = useParams();

  const toast = useCustomToast();
  const errorToast = useErrorToast();
  const apiError = useAPIErrorsToast();

  const {
    data: syncFetchResponse,
    isLoading,
    isError,
  } = useGetSyncById(syncId as string, activeWorkspaceId);

  const syncData = syncFetchResponse?.data?.attributes;

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

  return (
    <ContentContainer>
      {isLoading || !syncData ? <Loader /> : null}
      <TopBar
        name='Sync'
        breadcrumbSteps={EDIT_SYNC_FORM_STEPS}
        extra={
          syncData && (
            <SyncDetails
              syncData={syncData}
              syncId={syncId}
              activeWorkspaceId={activeWorkspaceId}
            />
          )
        }
      />
      <Box display='flex' justifyContent='space-between'>
        <TabsWrapper>
          <TabList gap='8px'>
            <TabItem text='Sync Runs' action={() => setSyncTab(SyncTabs.Runs)} />
            <TabItem text='Configuration' action={() => setSyncTab(SyncTabs.Config)} />
          </TabList>
        </TabsWrapper>
        {syncTab === SyncTabs.Config && (
          <Box display='flex' flexDir='row' gap='12px'>
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
          </Box>
        )}
      </Box>
      <Box pb={1}>
        <SyncTabContent syncTab={syncTab} />
      </Box>
    </ContentContainer>
  );
};

export default ViewSync;
