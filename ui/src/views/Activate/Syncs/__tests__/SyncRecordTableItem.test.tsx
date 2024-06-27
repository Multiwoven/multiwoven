import { render, screen, fireEvent } from '@testing-library/react';
import { TableItem } from '../SyncRecords/SyncRecordsTableItem';
import { SyncRecordResponse, SyncRecordStatus } from '../types';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
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
        status: SyncRecordStatus.success,
        action: 'destination_insert',
        error: {
          message: '',
          code: '',
        },
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
        status: SyncRecordStatus.failed,
        action: 'destination_insert',
        error: {
          message: 'Invalid input type',
          code: '',
        },
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

  it('should render error text in the column if status is failed and error message is valid', () => {
    render(<TableItem field='error' data={data[1]} />);
    expect(screen.getByText('Error')).toBeTruthy();
  });

  it('should open a modal and display the error message when error text is clicked', () => {
    render(<TableItem field='error' data={data[1]} />);
    const errorElement = screen.getByText('Error');

    // Simulate click event
    fireEvent.click(errorElement);

    expect(screen.getByText('Invalid input type')).toBeInTheDocument();
  });

  it('should render the records with the correct tag', () => {
    const successfulRow = render(<TableItem field='name' data={data[0]} />);
    expect(successfulRow.getByText('John Doe')).toBeTruthy();

    const failedRow = render(<TableItem field='name' data={data[1]} />);
    expect(failedRow.getByText('Jane Doe')).toBeTruthy();
  });
});
