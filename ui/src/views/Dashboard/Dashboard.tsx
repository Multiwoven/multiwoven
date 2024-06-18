import { Stack, Tab, TabIndicator, TabList, Tabs, Box, Text } from '@chakra-ui/react';
import ContentContainer from '@/components/ContentContainer';
import TopBar from '@/components/TopBar';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Legend,
  Tooltip,
} from 'chart.js';
import { ReportTimePeriod, getReport, Report } from '@/services/dashboard';

import { getAllConnectors } from '@/services/connectors';
import { useEffect, useState } from 'react';
import ListConnectors from './ListConnectors';
import { ConnectorItem } from '../Connectors/types';
import Reports from './Reports';
import Loader from '@/components/Loader';
import ReportsSkeleton from './Reports/Skeleton/Reports';
import ServerError from '../ServerError';
import useCustomToast from '@/hooks/useCustomToast';
import { CustomToastStatus } from '@/components/Toast';
import useQueryWrapper from '@/hooks/useQueryWrapper';
import { ConnectorListResponse } from '@/views/Connectors/types';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

const TabName = ({ title, onClick }: { title: string; onClick?: () => void }) => (
  <Tab
    _selected={{
      backgroundColor: 'gray.100',
      borderRadius: '4px',
      color: 'black.500',
    }}
    color='black.200'
    onClick={onClick}
  >
    <Text size='xs' fontWeight='semibold'>
      {title}
    </Text>
  </Tab>
);

const Dashboard = (): JSX.Element | null => {
  const [filteredConnectorsList, setFilteredConnectorsList] = useState<ConnectorItem[]>();
  const [reportTime, setReportTime] = useState<ReportTimePeriod>('one_day');
  const [report, setReport] = useState<Report>();
  const [checkedConnectorIds, setCheckedConnectorIds] = useState<number[]>([]);
  const toast = useCustomToast();

  const { data, isLoading, error } = useQueryWrapper<ConnectorListResponse, Error>(
    ['connectors', 'dashboard'],
    () => getAllConnectors(),
    {
      refetchOnMount: true,
      refetchOnWindowFocus: false,
    },
  );

  useEffect(() => {
    setFilteredConnectorsList(data?.data);
  }, [data]);

  const {
    data: reportData,
    isLoading: reportsDataLoading,
    error: reportsError,
  } = useQueryWrapper<Report, Error>(
    ['dashboard', 'syncs', reportTime, checkedConnectorIds],
    () => getReport({ time_period: reportTime, connector_ids: [...checkedConnectorIds] }),
    {
      refetchOnMount: true,
      refetchOnWindowFocus: false,
    },
  );

  useEffect(() => {
    setReport(reportData);
  }, [reportData]);

  const setReportTimePeriod = (timePeriod: ReportTimePeriod) => {
    setReportTime(timePeriod);
  };

  const syncRunTriggeredData = report?.data?.sync_run_triggered;
  const syncRunRowsData = report?.data?.total_sync_run_rows;

  if (isLoading) {
    return <Loader />;
  }

  if (error || reportsError) {
    toast({
      title: 'Error: There was a connection error to the server. Please try again later.',
      status: CustomToastStatus.Error,
      isClosable: true,
      position: 'bottom-right',
    });
    return <ServerError />;
  }

  return (
    <Box width='100%' display='flex' flexDirection='column' alignItems='center'>
      <ContentContainer>
        <TopBar
          name={'Dashboard'}
          ctaName=''
          ctaButtonVariant='solid'
          onCtaClicked={() => {}}
          isCtaVisible={false}
        />
        <Box display='flex' gap='24px'>
          <Box>
            <ListConnectors
              connectorsList={data?.data}
              checkedConnectorIds={checkedConnectorIds}
              filteredConnectorsList={filteredConnectorsList}
              setFilteredConnectorsList={setFilteredConnectorsList}
              setCheckedConnectorIds={setCheckedConnectorIds}
            />
          </Box>
          <Box>
            <Stack gap='32px'>
              <Stack spacing='16'>
                <Tabs
                  size='md'
                  variant='indicator'
                  background='gray.300'
                  padding={1}
                  borderRadius='8px'
                  borderStyle='solid'
                  borderWidth='1px'
                  borderColor='gray.400'
                  width='fit-content'
                >
                  <TabList gap='8px'>
                    <TabName title='24hr' onClick={() => setReportTimePeriod('one_day')} />
                    <TabName title='7d' onClick={() => setReportTimePeriod('one_week')} />
                  </TabList>
                  <TabIndicator />
                </Tabs>
              </Stack>
              {syncRunTriggeredData && syncRunRowsData ? (
                <Reports
                  syncRunTriggeredData={syncRunTriggeredData}
                  syncRunRowsData={syncRunRowsData}
                />
              ) : (
                <ReportsSkeleton fetchingReports={reportsDataLoading} />
              )}
            </Stack>
          </Box>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default Dashboard;
