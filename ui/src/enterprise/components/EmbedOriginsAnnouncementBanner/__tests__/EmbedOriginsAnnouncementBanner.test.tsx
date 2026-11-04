import { fireEvent, screen, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach, afterEach } from '@jest/globals';
import '@testing-library/jest-dom';
import { renderWithProviders } from '@/utils/testUtils';
import EmbedOriginsAnnouncementBanner from '../EmbedOriginsAnnouncementBanner';

const DISMISSED_KEY = 'embed-origins-announcement-dismissed';

describe('EmbedOriginsAnnouncementBanner', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  afterEach(() => {
    localStorage.clear();
  });

  it('renders the banner when not dismissed', async () => {
    renderWithProviders(<EmbedOriginsAnnouncementBanner />);

    await waitFor(() => {
      expect(screen.getByTestId('embed-origins-announcement-banner')).toBeInTheDocument();
    });
    expect(screen.getByText(/Action required:/)).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /Allowed Origins/ })).toBeInTheDocument();
  });

  it('warns that already-running embeds are affected (not just new ones)', async () => {
    renderWithProviders(<EmbedOriginsAnnouncementBanner />);

    await waitFor(() => {
      expect(screen.getByTestId('embed-origins-announcement-banner')).toBeInTheDocument();
    });
    expect(screen.getByText(/must be listed under this workspace/i)).toBeInTheDocument();
    expect(screen.getByText(/including embeds that are already live/i)).toBeInTheDocument();
  });

  it('does not render when previously dismissed', async () => {
    localStorage.setItem(DISMISSED_KEY, 'true');
    renderWithProviders(<EmbedOriginsAnnouncementBanner />);

    await waitFor(() => {
      expect(screen.queryByTestId('embed-origins-announcement-banner')).not.toBeInTheDocument();
    });
  });

  it('dismisses the banner and sets localStorage when close button is clicked', async () => {
    renderWithProviders(<EmbedOriginsAnnouncementBanner />);

    await waitFor(() => {
      expect(screen.getByTestId('embed-origins-announcement-banner')).toBeInTheDocument();
    });

    fireEvent.click(screen.getByTestId('embed-origins-announcement-dismiss'));

    await waitFor(() => {
      expect(screen.queryByTestId('embed-origins-announcement-banner')).not.toBeInTheDocument();
    });
    expect(localStorage.getItem(DISMISSED_KEY)).toBe('true');
  });

  it('links to the embed origins settings page', async () => {
    renderWithProviders(<EmbedOriginsAnnouncementBanner />);

    await waitFor(() => {
      expect(screen.getByTestId('embed-origins-announcement-banner')).toBeInTheDocument();
    });

    const link = screen.getByRole('link', { name: /Allowed Origins/ });
    expect(link).toHaveAttribute('href', '/settings/embed-origins');
  });

  it('has role="status" for accessibility', async () => {
    renderWithProviders(<EmbedOriginsAnnouncementBanner />);

    await waitFor(() => {
      expect(screen.getByRole('status')).toBeInTheDocument();
    });
  });
});
