import { render, screen } from '@testing-library/react';
import { TableItem } from '../SyncRecords/SyncRecordsTableItem';
import { SyncRecordResponse } from '../types';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom';

describe('TableItem', () => {
  const data: SyncRecordResponse[] = [
    {
      id: '1',
      type: 'sync_records',
      attributes: {
        sync_id: '1',
        sync_run_id: '1',
        record: {
          id: '1',
          name: 'John Doe',
        },
        status: 'success',
        action: 'destination_insert',
        error: null,
        created_at: '',
        updated_at: 'string',
      },
    },
    {
      id: '2',
      type: 'sync_records',
      attributes: {
        sync_id: '1',
        sync_run_id: '2',
        record: {
          id: '2',
          name: 'Jane Doe',
        },
        status: 'failed',
        action: 'destination_insert',
        error: null,
        created_at: '',
        updated_at: 'string',
      },
    },
  ];
  it('should render status tag with success variant when status is success', () => {
    render(<TableItem field='status' data={data[0]} />);
    expect(screen.getByText('Added')).toBeTruthy();
  });

  it('should render status tag with failed variant when status is not success', () => {
    render(<TableItem field='status' data={data[1]} />);
    expect(screen.getByText('Failed')).toBeTruthy();
  });

  it('should render the records with the correct tag', () => {
    const successfulRow = render(<TableItem field='name' data={data[0]} />);
    expect(successfulRow.getByText('John Doe')).toBeTruthy();

    const failedRow = render(<TableItem field='name' data={data[1]} />);
    expect(failedRow.getByText('Jane Doe')).toBeTruthy();
  });
});
