import { Box, HStack, Spacer, Text, Tooltip as ChakraTooltip, Skeleton } from '@chakra-ui/react';
import { FiInfo } from 'react-icons/fi';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Legend,
  Tooltip,
} from 'chart.js';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

export const ChartSkeleton = ({
  fetchingReports,
}: {
  fetchingReports: boolean;
}): JSX.Element | null => {
  return (
    <Box
      w='356px'
      h='240px'
      px='20px'
      py='16px'
      display='flex'
      gap='3'
      flexDir='column'
      border='1'
      bgColor='gray.100'
      borderWidth='1px'
      borderRadius='8px'
      borderColor='gray.400'
    >
      <HStack>
        <Skeleton isLoaded={!fetchingReports}>
          <Text size='sm' fontWeight='semibold'>
            Chart title
          </Text>
        </Skeleton>
        <Spacer />
        <Skeleton isLoaded={!fetchingReports}>
          <ChakraTooltip hasArrow label='' fontSize='sm' placement='top-end'>
            <Text color='gray.600'>
              <FiInfo />
            </Text>
          </ChakraTooltip>
        </Skeleton>
      </HStack>
      <Box>
        <Skeleton isLoaded={!fetchingReports} height='180px' width='316px' />
      </Box>
      <Box position='relative' left='40%' bottom='60%'>
        <Skeleton
          isLoaded={!fetchingReports}
          w='fit-content'
          h='20px'
          alignItems='center'
          alignContent='center'
          bgColor='gray.200'
          border='1px'
          borderRadius='4px'
          borderColor='gray.400'
          gap='10px'
          px='2px'
          display='flex'
        >
          <Text size='xxs' fontWeight='semibold' color='black.100'></Text>
        </Skeleton>
      </Box>
    </Box>
  );
};
