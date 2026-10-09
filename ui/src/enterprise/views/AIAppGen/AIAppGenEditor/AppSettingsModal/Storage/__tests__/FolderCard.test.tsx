import { screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';

import { renderWithProviders } from '@/utils/testUtils';

import { FolderCard } from '../FolderCard';
import type { Folder } from '../types';

const folder: Folder = { id: 'avatars', name: 'avatars', is_public: false };

const cardEl = () => screen.getByTestId('app-builder-folder-avatars');

beforeEach(() => {
  jest.clearAllMocks();
});

describe('FolderCard — rendering', () => {
  it('renders the folder name and a Private tag for a private folder', () => {
    renderWithProviders(<FolderCard folder={folder} />);
    expect(screen.getByTestId('app-builder-folder-avatars')).toBeInTheDocument();
    expect(screen.getByText('avatars')).toBeInTheDocument();
    expect(screen.getByText('Private')).toBeInTheDocument();
  });

  it('renders a Public tag for a public folder', () => {
    renderWithProviders(<FolderCard folder={{ ...folder, is_public: true }} />);
    expect(screen.getByText('Public')).toBeInTheDocument();
  });

  it('is keyboard-focusable when onClick is provided (tabIndex 0)', () => {
    renderWithProviders(<FolderCard folder={folder} onClick={jest.fn()} />);
    expect(cardEl()).toHaveAttribute('tabindex', '0');
  });

  it('is not focusable when onClick is omitted (tabIndex -1)', () => {
    renderWithProviders(<FolderCard folder={folder} />);
    expect(cardEl()).toHaveAttribute('tabindex', '-1');
  });
});

describe('FolderCard — interactions', () => {
  it('fires onClick when the card is clicked', () => {
    const onClick = jest.fn();
    renderWithProviders(<FolderCard folder={folder} onClick={onClick} />);
    fireEvent.click(screen.getByTestId('app-builder-folder-avatars'));
    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it('fires onClick on Enter and Space keydown', () => {
    const onClick = jest.fn();
    renderWithProviders(<FolderCard folder={folder} onClick={onClick} />);
    fireEvent.keyDown(cardEl(), { key: 'Enter' });
    fireEvent.keyDown(cardEl(), { key: ' ' });
    expect(onClick).toHaveBeenCalledTimes(2);
  });

  it('does not fire onClick on other keys', () => {
    const onClick = jest.fn();
    renderWithProviders(<FolderCard folder={folder} onClick={onClick} />);
    fireEvent.keyDown(cardEl(), { key: 'a' });
    expect(onClick).not.toHaveBeenCalled();
  });

  it('ignores keydown entirely when onClick is omitted', () => {
    renderWithProviders(<FolderCard folder={folder} />);
    // Should not throw when no handler is wired.
    fireEvent.keyDown(cardEl(), { key: 'Enter' });
    expect(cardEl()).toBeInTheDocument();
  });
});

describe('FolderCard — delete affordance', () => {
  it('renders a delete button only when onDelete is provided', () => {
    const { rerender } = renderWithProviders(<FolderCard folder={folder} />);
    expect(screen.queryByTestId('app-builder-delete-folder-avatars')).not.toBeInTheDocument();
    rerender(<FolderCard folder={folder} onDelete={jest.fn()} />);
    expect(screen.getByTestId('app-builder-delete-folder-avatars')).toBeInTheDocument();
  });

  it('fires onDelete without bubbling to the card onClick', () => {
    const onClick = jest.fn();
    const onDelete = jest.fn();
    renderWithProviders(<FolderCard folder={folder} onClick={onClick} onDelete={onDelete} />);
    fireEvent.click(screen.getByTestId('app-builder-delete-folder-avatars'));
    expect(onDelete).toHaveBeenCalledTimes(1);
    // stopPropagation keeps the navigation onClick from firing.
    expect(onClick).not.toHaveBeenCalled();
  });
});
