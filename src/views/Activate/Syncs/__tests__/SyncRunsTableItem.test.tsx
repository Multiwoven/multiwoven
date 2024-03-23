import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { TableItem } from '@/views/Activate/Syncs/SyncRuns/SyncRunTableItem';
import { SyncRunsResponse } from '../types';
import { expect } from '@jest/globals';

const mockSyncRunsData: SyncRunsResponse[] = [
  {
    id: '1',
    type: 'sync_runs',
    attributes: {
      sync_id: '1',
      status: 'success',
      source_id: '2',
      destination_id: '3',
      started_at: '2024-01-01T00:00:00.000Z',
      finished_at: '2024-01-01T00:00:00.000Z',
      created_at: '2024-01-01T00:00:00.000Z',
      updated_at: '2024-01-01T00:00:00.000Z',
      duration: 1.0,
      total_query_rows: 500,
      total_rows: 500,
      successful_rows: 500,
      failed_rows: 0,
      error: null,
    },
  },
  {
    id: '2',
    type: 'sync_runs',
    attributes: {
      sync_id: '1',
      status: 'failed',
      source_id: '2',
      destination_id: '3',
      started_at: '2024-03-15T07:26:00.345Z',
      finished_at: '2024-03-15T07:26:07.374Z',
      created_at: '2024-03-15T07:26:00.299Z',
      updated_at: '2024-03-15T07:26:07.378Z',
      duration: 1.0,
      total_query_rows: 500,
      total_rows: 500,
      successful_rows: 450,
      failed_rows: 50,
      error: null,
    },
  },
];

describe('TableItem', () => {
  it('should render start time correctly', () => {
    render(<TableItem field='start_time' data={mockSyncRunsData[0]} />);
    expect(screen.getByText('01/01/2024 at 00:00 am')).toBeTruthy();
  });

  it('should render duration correctly', () => {
    render(<TableItem field='duration' data={mockSyncRunsData[0]} />);
    expect(screen.getByText('1 seconds')).toBeTruthy();
  });

  it('should render rows queried correctly', () => {
    render(<TableItem field='rows_queried' data={mockSyncRunsData[0]} />);
    expect(screen.getByText('500 rows')).toBeTruthy();
  });

  it('should render status correctly for success', () => {
    render(<TableItem field='status' data={mockSyncRunsData[0]} />);
    expect(screen.getByText('Healthy')).toBeTruthy();
  });

  it('should render status correctly for failure', () => {
    render(<TableItem field='status' data={mockSyncRunsData[1]} />);
    expect(screen.getByText('Failed')).toBeTruthy();
  });

  it('should render results correctly with correct class', () => {
    render(<TableItem field='results' data={mockSyncRunsData[0]} />);
    const element = screen.getByText('500');
    const classes = element.className;

    expect(classes.includes('css-142whxk')).toBeTruthy();
    expect(screen.getByText('500')).toBeTruthy();
    expect(screen.getByText('Successful')).toBeTruthy();
  });

  it('should render results correctly for failure with correct class', () => {
    render(<TableItem field='results' data={mockSyncRunsData[1]} />);
    const element = screen.getByText('50');
    const classes = element.className;

    expect(classes.includes('css-1q45uzp')).toBeTruthy();
    expect(screen.getByText('50')).toBeTruthy();
    expect(screen.getByText('Failed')).toBeTruthy();
  });
});
