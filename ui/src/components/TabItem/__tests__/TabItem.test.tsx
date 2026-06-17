import { render, screen, fireEvent } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider, Tabs } from '@chakra-ui/react';
import TabItem from '../TabItem';
import { FiHome } from 'react-icons/fi';

const renderTabItem = (props = {}) => {
  return render(
    <ChakraProvider>
      <Tabs>
        <TabItem text='Test Tab' {...props} />
      </Tabs>
    </ChakraProvider>,
  );
};

describe('TabItem', () => {
  const mockAction = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should render text', () => {
    renderTabItem({ text: 'Test Tab' });
    expect(screen.getByText('Test Tab')).toBeInTheDocument();
  });

  it('should render with correct test id', () => {
    renderTabItem({ text: 'Test Tab' });
    expect(screen.getByTestId('tab-item-Test Tab')).toBeInTheDocument();
  });

  it('should prefer explicit testId over text-based id', () => {
    renderTabItem({ text: 'Workflow', testId: 'tab-item-workflow' });
    expect(screen.getByTestId('tab-item-workflow')).toBeInTheDocument();
  });

  it('should call action when clicked', () => {
    renderTabItem({ text: 'Test Tab', action: mockAction });
    const tab = screen.getByTestId('tab-item-Test Tab');
    fireEvent.click(tab);
    expect(mockAction).toHaveBeenCalledTimes(1);
  });

  it('should render badge when isBadgeVisible is true and badgeText is provided', () => {
    renderTabItem({
      text: 'Test Tab',
      isBadgeVisible: true,
      badgeText: '5',
    });
    expect(screen.getByText('5')).toBeInTheDocument();
  });

  it('should not render badge when isBadgeVisible is false', () => {
    renderTabItem({
      text: 'Test Tab',
      isBadgeVisible: false,
      badgeText: '5',
    });
    expect(screen.queryByText('5')).not.toBeInTheDocument();
  });

  it('should not render badge when badgeText is not provided', () => {
    renderTabItem({
      text: 'Test Tab',
      isBadgeVisible: true,
    });
    // Badge should not render without badgeText
    const badge = screen.queryByTestId('tab-badge');
    expect(badge).not.toBeInTheDocument();
  });

  it('should render icon when provided', () => {
    renderTabItem({
      text: 'Test Tab',
      icon: <FiHome data-testid='tab-icon' />,
    });
    expect(screen.getByTestId('tab-icon')).toBeInTheDocument();
  });

  it('should render extra content when provided', () => {
    renderTabItem({
      text: 'Test Tab',
      extra: <div data-testid='extra-content'>Extra</div>,
    });
    expect(screen.getByTestId('extra-content')).toBeInTheDocument();
  });

  it('should render with custom height', () => {
    renderTabItem({
      text: 'Test Tab',
      height: '40px',
    });
    const tab = screen.getByTestId('tab-item-Test Tab');
    expect(tab).toBeInTheDocument();
  });

  it('should render with custom padding', () => {
    renderTabItem({
      text: 'Test Tab',
      px: '16px',
      py: '8px',
    });
    expect(screen.getByTestId('tab-item-Test Tab')).toBeInTheDocument();
  });

  it('should render with flex prop', () => {
    renderTabItem({
      text: 'Test Tab',
      flex: 1,
    });
    expect(screen.getByTestId('tab-item-Test Tab')).toBeInTheDocument();
  });

  it('should handle selected state styling', () => {
    renderTabItem({
      text: 'Test Tab',
      _selected: {
        backgroundColor: 'blue.100',
      },
    });
    const tab = screen.getByTestId('tab-item-Test Tab');
    expect(tab).toBeInTheDocument();
  });

  it('should render all props together', () => {
    renderTabItem({
      text: 'Complete Tab',
      action: mockAction,
      isBadgeVisible: true,
      badgeText: '10',
      icon: <FiHome data-testid='complete-icon' />,
      extra: <div data-testid='complete-extra'>Extra</div>,
    });
    expect(screen.getByText('Complete Tab')).toBeInTheDocument();
    expect(screen.getByText('10')).toBeInTheDocument();
    expect(screen.getByTestId('complete-icon')).toBeInTheDocument();
    expect(screen.getByTestId('complete-extra')).toBeInTheDocument();
  });

  it('should not call action when action is not provided', () => {
    renderTabItem({ text: 'Test Tab' });
    const tab = screen.getByTestId('tab-item-Test Tab');
    // Should not throw error
    fireEvent.click(tab);
  });
});
