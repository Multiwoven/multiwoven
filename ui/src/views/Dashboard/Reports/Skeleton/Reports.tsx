import { Box, VStack } from '@chakra-ui/react';
import { ChartSkeleton } from './ChartSkeleton';
const Reports = ({ fetchingReports }: { fetchingReports: boolean }): JSX.Element => {
  return (
    <>
      <Box display={{ base: 'flex flex-col', lg: 'flex' }} gap={4}>
        <VStack gap={4}>
          <ChartSkeleton fetchingReports={fetchingReports} />
          <ChartSkeleton fetchingReports={fetchingReports} />
        </VStack>
        <VStack gap={4}>
          <ChartSkeleton fetchingReports={fetchingReports} />
          <ChartSkeleton fetchingReports={fetchingReports} />
        </VStack>
      </Box>
    </>
  );
};

export default Reports;
