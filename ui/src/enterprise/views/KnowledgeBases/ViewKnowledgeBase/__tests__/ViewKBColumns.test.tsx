import type { ReactElement } from 'react';
import { render, screen } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { ViewKBColumns } from '../ViewKBColumns';

describe('ViewKBColumns', () => {
  const handlers = {
    handleDownload: jest.fn(),
    handlePreview: jest.fn(),
    handleDelete: jest.fn(),
  };

  const renderStatusCell = (uploadStatus: string) => {
    const columns = ViewKBColumns(handlers);
    const statusColumn = columns.find(
      (c) => 'accessorKey' in c && c.accessorKey === 'attributes.upload_status',
    );
    expect(statusColumn?.cell).toBeDefined();
    const Cell = statusColumn!.cell as (ctx: { getValue: () => string }) => ReactElement;
    return render(<ChakraProvider>{Cell({ getValue: () => uploadStatus })}</ChakraProvider>);
  };

  it('maps upload_status to a hyphenated kb-file-status test id', () => {
    renderStatusCell('failed_to_delete');
    expect(screen.getByTestId('kb-file-status-failed-to-delete')).toHaveTextContent(
      'Failed to Delete',
    );
  });

  it('uses the processing slug for the processing status', () => {
    renderStatusCell('processing');
    expect(screen.getByTestId('kb-file-status-processing')).toHaveTextContent('Processing');
  });

  it('uses the processing test id for unknown upload_status so it matches the Processing label', () => {
    renderStatusCell('unknown_api_value');
    expect(screen.getByTestId('kb-file-status-processing')).toHaveTextContent('Processing');
  });
});
