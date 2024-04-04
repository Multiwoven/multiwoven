import { render } from '@testing-library/react';
import Reports from '@/views/Dashboard/Reports/Reports'; // Adjust the import path as necessary
import { ChartCard } from '@/views/Dashboard/Reports/ChartCard';
import { ReportObject } from '@/services/dashboard';
import { expect } from '@jest/globals';

jest.mock('@/views/Dashboard/Reports/ChartCard', () => {
  return {
    __esModule: true,
    ChartCard: jest.fn((props) => <div data-testid='mockChartCard' {...props} />),
  };
});

it('should passes correct props to ChartCard', () => {
  const mockData: ReportObject[] = [
    { time_slice: '2021-01-01T00:00:00Z', failed_count: 2, success_count: 98, total_count: 100 },
  ];

  render(<Reports syncRunTriggeredData={mockData} syncRunRowsData={mockData} />);

  const ChartCardMock = jest.mocked(ChartCard);

  expect(ChartCardMock).toHaveBeenCalledWith(
    expect.objectContaining({
      data: expect.objectContaining({
        xData: mockData,
      }),
    }),
    expect.anything(),
  );
});
