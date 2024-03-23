import { Box, HStack, Spacer, Text, Tooltip as ChakraTooltip } from '@chakra-ui/react';
import { FiInfo } from 'react-icons/fi';
import { Bar } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Legend,
  Tooltip,
} from 'chart.js';
import { ChartData, ChartDataType } from '../types';
import moment from 'moment';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

type ChartCardProps = {
  data: ChartDataType;
  tooltipLabel: string;
  cardTitle: string;
  chartEmptyText?: string;
  tooltipPosition?: 'top' | 'top-start' | 'top-end' | undefined;
};

const options = {
  responsive: true,
  plugins: {
    legend: {
      display: false,
    },
  },
  interaction: {
    mode: 'index' as const,
  },
  scales: {
    x: {
      stacked: true,
      barThickness: '10px',
      ticks: {
        maxTicksLimit: 4,
        fontFamily: 'Manrope',
      },
      grid: { color: '#F2F4F7' },
    },
    y: {
      stacked: true,
      ticks: {
        stepSize: 1,
        fontFamily: 'Manrope',
        maxTicksLimit: 4,
      },
      grid: { color: '#F2F4F7' },
    },
  },
};

export const ChartCard = ({
  data,
  tooltipLabel,
  cardTitle,
  tooltipPosition = 'top',
  chartEmptyText = 'No Data found',
}: ChartCardProps): JSX.Element | null => {
  const labels = data.xData.map((run) => moment(run.time_slice).format('ddd hh:mm'));
  const datasets = data.yDataPoints.map((dataPoint) => ({
    label: data.yLabels[dataPoint],
    data: data.yData.map((run) => Number(run[dataPoint])),
    backgroundColor: data.backgroundColors[dataPoint],
  }));

  const chartData: ChartData = {
    labels: labels,
    datasets: datasets,
  };

  const totalSum = chartData.datasets.reduce((total, dataset) => {
    const datasetSum = dataset.data.reduce((sum, value) => sum + value, 0);
    return total + datasetSum;
  }, 0);

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
        <Text size='sm' fontWeight='semibold'>
          {cardTitle}
        </Text>
        <Spacer />
        <ChakraTooltip
          hasArrow
          label={tooltipLabel}
          fontSize='xs'
          placement={tooltipPosition}
          backgroundColor='black.500'
          color='gray.100'
          borderRadius='6px'
          padding='8px'
        >
          <Text color='gray.600'>
            <FiInfo />
          </Text>
        </ChakraTooltip>
      </HStack>
      <Box opacity={totalSum > 0 ? '100%' : '40%'}>
        <Bar height='180px' width='316px' options={options} data={chartData} />
      </Box>
      {totalSum === 0 ? (
        <Box position='relative' left='40%' bottom='60%'>
          <Box
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
            <Text size='xxs' fontWeight='semibold' color='black.100'>
              {chartEmptyText}
            </Text>
          </Box>
        </Box>
      ) : null}
    </Box>
  );
};
