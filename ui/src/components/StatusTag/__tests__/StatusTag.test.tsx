import { render, screen } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import StatusTag, { StatusTagVariants, StatusTagText } from '../StatusTag';

const renderStatusTag = (props = {}) => {
  return render(
    <ChakraProvider>
      <StatusTag status='Test Status' {...props} />
    </ChakraProvider>,
  );
};

describe('StatusTag', () => {
  it('should render status text', () => {
    renderStatusTag({ status: 'Test Status' });
    expect(screen.getByText('Test Status')).toBeInTheDocument();
  });

  it('should render with default success variant', () => {
    renderStatusTag({ status: 'Success' });
    const tag = screen.getByText('Success');
    expect(tag).toBeInTheDocument();
  });

  it('should render success variant', () => {
    renderStatusTag({
      status: StatusTagText.success,
      variant: StatusTagVariants.success,
    });
    expect(screen.getByText(StatusTagText.success)).toBeInTheDocument();
  });

  it('should render processed variant', () => {
    renderStatusTag({
      status: StatusTagText.processed,
      variant: StatusTagVariants.success,
    });
    expect(screen.getByText(StatusTagText.processed)).toBeInTheDocument();
  });

  it('should render failed variant', () => {
    renderStatusTag({
      status: StatusTagText.failed,
      variant: StatusTagVariants.failed,
    });
    expect(screen.getByText(StatusTagText.failed)).toBeInTheDocument();
  });

  it('should render pending variant', () => {
    renderStatusTag({
      status: StatusTagText.pending,
      variant: StatusTagVariants.pending,
    });
    expect(screen.getByText(StatusTagText.pending)).toBeInTheDocument();
  });

  it('should render in_progress variant', () => {
    renderStatusTag({
      status: StatusTagText.in_progress,
      variant: StatusTagVariants.in_progress,
    });
    expect(screen.getByText(StatusTagText.in_progress)).toBeInTheDocument();
  });

  it('should render started variant', () => {
    renderStatusTag({
      status: StatusTagText.started,
      variant: StatusTagVariants.started,
    });
    expect(screen.getByText(StatusTagText.started)).toBeInTheDocument();
  });

  it('should render querying variant', () => {
    renderStatusTag({
      status: StatusTagText.querying,
      variant: StatusTagVariants.querying,
    });
    expect(screen.getByText(StatusTagText.querying)).toBeInTheDocument();
  });

  it('should render queued variant', () => {
    renderStatusTag({
      status: StatusTagText.queued,
      variant: StatusTagVariants.queued,
    });
    expect(screen.getByText(StatusTagText.queued)).toBeInTheDocument();
  });

  it('should render paused variant', () => {
    renderStatusTag({
      status: StatusTagText.paused,
      variant: StatusTagVariants.paused,
    });
    expect(screen.getByText(StatusTagText.paused)).toBeInTheDocument();
  });

  it('should render info variant', () => {
    renderStatusTag({
      status: StatusTagText.info,
      variant: StatusTagVariants.info,
    });
    expect(screen.getByText(StatusTagText.info)).toBeInTheDocument();
  });

  it('should render canceled variant', () => {
    renderStatusTag({
      status: StatusTagText.canceled,
      variant: StatusTagVariants.canceled,
    });
    expect(screen.getByText(StatusTagText.canceled)).toBeInTheDocument();
  });

  it('should render draft variant', () => {
    renderStatusTag({
      status: StatusTagText.draft,
      variant: StatusTagVariants.draft,
    });
    expect(screen.getByText(StatusTagText.draft)).toBeInTheDocument();
  });

  it('should render processing variant', () => {
    renderStatusTag({
      status: StatusTagText.processing,
      variant: StatusTagVariants.draft,
    });
    expect(screen.getByText(StatusTagText.processing)).toBeInTheDocument();
  });

  it('should render custom status text', () => {
    renderStatusTag({ status: 'Custom Status', variant: StatusTagVariants.success });
    expect(screen.getByText('Custom Status')).toBeInTheDocument();
  });

  it('should set data-testid on the tag when testId is provided', () => {
    renderStatusTag({ status: 'Ready', testId: 'kb-file-status-ready' });
    expect(screen.getByTestId('kb-file-status-ready')).toHaveTextContent('Ready');
  });

  it('should render all variants correctly', () => {
    const variants = Object.values(StatusTagVariants);
    variants.forEach((variant) => {
      const { unmount } = renderStatusTag({
        status: `Status ${variant}`,
        variant,
      });
      expect(screen.getByText(`Status ${variant}`)).toBeInTheDocument();
      unmount();
    });
  });
});
