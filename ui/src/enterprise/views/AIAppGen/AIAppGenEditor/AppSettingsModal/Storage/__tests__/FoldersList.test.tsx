import { screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';

import { renderWithProviders } from '@/utils/testUtils';

import { FoldersList } from '../FoldersList';
import type { Folder } from '../types';

const folders: Folder[] = [
  { id: 'avatars', name: 'avatars', is_public: true },
  { id: 'docs', name: 'docs', is_public: false },
];

beforeEach(() => {
  jest.clearAllMocks();
});

describe('FoldersList', () => {
  it('renders the empty state when there are no folders', () => {
    renderWithProviders(<FoldersList folders={[]} />);
    expect(screen.getByText(/no folders/i)).toBeInTheDocument();
  });

  it('renders a card per folder', () => {
    renderWithProviders(<FoldersList folders={folders} />);
    expect(screen.getByTestId('app-builder-folder-avatars')).toBeInTheDocument();
    expect(screen.getByTestId('app-builder-folder-docs')).toBeInTheDocument();
  });

  it('fires onSelectFolder when a card is clicked', () => {
    const onSelectFolder = jest.fn();
    renderWithProviders(<FoldersList folders={folders} onSelectFolder={onSelectFolder} />);
    fireEvent.click(screen.getByTestId('app-builder-folder-avatars'));
    expect(onSelectFolder).toHaveBeenCalledWith(folders[0]);
  });

  it('fires onDeleteFolder when a card delete is clicked', () => {
    const onDeleteFolder = jest.fn();
    renderWithProviders(<FoldersList folders={folders} onDeleteFolder={onDeleteFolder} />);
    fireEvent.click(screen.getByTestId('app-builder-delete-folder-docs'));
    expect(onDeleteFolder).toHaveBeenCalledWith(folders[1]);
  });

  it('renders no delete affordances when onDeleteFolder is omitted', () => {
    renderWithProviders(<FoldersList folders={folders} />);
    expect(screen.queryByTestId('app-builder-delete-folder-avatars')).not.toBeInTheDocument();
    expect(screen.queryByTestId('app-builder-delete-folder-docs')).not.toBeInTheDocument();
  });

  it('does not throw when a card is clicked without onSelectFolder', () => {
    renderWithProviders(<FoldersList folders={folders} />);
    fireEvent.click(screen.getByText('avatars'));
    expect(screen.getByText('avatars')).toBeInTheDocument();
  });
});
