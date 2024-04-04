import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { ChartCard } from '@/views/Dashboard/Reports/ChartCard'; // Adjust the import path to match your file structure
import { ChartDataType } from '../types';

jest.mock('moment');
jest.mock('react-chartjs-2');

describe('ChartCard', () => {
  const mockData: ChartDataType = {
    xData: [
      { total_count: 30, success_count: 20, failed_count: 10, time_slice: '2022-01-01T00:00:00Z' },
      { total_count: 25, success_count: 15, failed_count: 10, time_slice: '2022-01-02T00:00:00Z' },
    ],
    yDataPoints: ['total_count'],
    xDataPoints: ['time_slice'],
    yLabels: { total_count: 'Total' },
    yData: [
      { total_count: 30, success_count: 20, failed_count: 10, time_slice: '2022-01-01T00:00:00Z' },
      { total_count: 25, success_count: 15, failed_count: 10, time_slice: '2022-01-02T00:00:00Z' },
    ],
    backgroundColors: { total_count: 'green' },
  };

  it('should render chart card with correct data', () => {
    render(
      <ChartCard
        data={mockData}
        tooltipLabel='Tooltip Label'
        cardTitle='Card Title'
        tooltipPosition='top'
        chartEmptyText='No Data found'
      />,
    );

    expect(screen.getByText('Card Title'));
  });

  it('should render chart card with no data', () => {
    render(
      <ChartCard
        data={{
          xData: [],
          yData: [],
          xDataPoints: [],
          yDataPoints: [],
          yLabels: {},
          backgroundColors: {},
        }}
        tooltipLabel='Tooltip Label'
        cardTitle='Card Title'
        tooltipPosition='top'
        chartEmptyText='No Data found'
      />,
    );

    expect(screen.getByText('Card Title'));
    expect(screen.getByText('No Data found'));
  });
});
