import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider, Tabs } from '@chakra-ui/react';
import { FilterTabs } from '../FilterTabs';
import { SyncRecordStatus } from '../../types';

const renderComponent = (setFilter: (status: SyncRecordStatus) => void) => {
  return render(
    <ChakraProvider>
      <Tabs>
        <FilterTabs setFilter={setFilter} />
      </Tabs>
    </ChakraProvider>,
  );
};

describe('FilterTabs', () => {
  it('renders both tab items', () => {
    const mockSetFilter = jest.fn();
    renderComponent(mockSetFilter);
    expect(screen.getByText('Successful')).toBeInTheDocument();
    expect(screen.getByText('Rejected')).toBeInTheDocument();
  });

  it('calls setFilter with success status when Successful tab is clicked', () => {
    const mockSetFilter = jest.fn();
    renderComponent(mockSetFilter);
    const successTab = screen.getByText('Successful');
    fireEvent.click(successTab);
    expect(mockSetFilter).toHaveBeenCalledWith(SyncRecordStatus.success);
  });

  it('calls setFilter with failed status when Rejected tab is clicked', () => {
    const mockSetFilter = jest.fn();
    renderComponent(mockSetFilter);
    const rejectedTab = screen.getByText('Rejected');
    fireEvent.click(rejectedTab);
    expect(mockSetFilter).toHaveBeenCalledWith(SyncRecordStatus.failed);
  });
});
