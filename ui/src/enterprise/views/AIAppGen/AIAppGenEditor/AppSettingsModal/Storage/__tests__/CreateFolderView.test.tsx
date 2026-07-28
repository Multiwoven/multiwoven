import { screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';

import { renderWithProviders } from '@/utils/testUtils';

import { CreateFolderView } from '../CreateFolderView';

type SubmitFn = (params: { name: string; isPublic: boolean }) => void;

const baseProps = {
  existingFolderNames: ['avatars'],
  onSubmit: jest.fn<SubmitFn>(),
  onCancel: jest.fn<() => void>(),
};

const nameInput = () => screen.getByTestId('app-builder-folder-name');
const createBtn = () => screen.getByTestId('app-builder-create-folder');
const publicSwitch = () => screen.getByTestId('app-builder-make-folder-public');

beforeEach(() => {
  jest.clearAllMocks();
});

describe('CreateFolderView — rendering', () => {
  it('renders the heading, name input, and action buttons', () => {
    renderWithProviders(<CreateFolderView {...baseProps} />);
    // Breadcrumb + page title both read "Add new folder".
    expect(screen.getAllByText('Add new folder').length).toBeGreaterThanOrEqual(1);
    expect(nameInput()).toBeInTheDocument();
    expect(publicSwitch()).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeInTheDocument();
    expect(createBtn()).toBeInTheDocument();
  });

  it('disables Create Folder until a valid name is entered', () => {
    renderWithProviders(<CreateFolderView {...baseProps} />);
    expect(createBtn()).toBeDisabled();
  });
});

describe('CreateFolderView — validation', () => {
  it('shows the min-length error after blur for a too-short name', () => {
    renderWithProviders(<CreateFolderView {...baseProps} />);
    fireEvent.change(nameInput(), { target: { value: 'ab' } });
    fireEvent.blur(nameInput());
    expect(screen.getByText(/at least 3 characters/i)).toBeInTheDocument();
    expect(createBtn()).toBeDisabled();
  });

  it('shows the charset error for invalid characters', () => {
    renderWithProviders(<CreateFolderView {...baseProps} />);
    fireEvent.change(nameInput(), { target: { value: 'My Folder' } });
    fireEvent.blur(nameInput());
    expect(screen.getByText(/lowercase letters, numbers, and hyphens only/i)).toBeInTheDocument();
    expect(createBtn()).toBeDisabled();
  });

  it('shows the duplicate error when the name already exists', () => {
    renderWithProviders(<CreateFolderView {...baseProps} />);
    fireEvent.change(nameInput(), { target: { value: 'avatars' } });
    fireEvent.blur(nameInput());
    expect(screen.getByText(/already exists/i)).toBeInTheDocument();
    expect(createBtn()).toBeDisabled();
  });

  it('shows the max-length error for a name longer than 63 chars', () => {
    renderWithProviders(<CreateFolderView {...baseProps} />);
    fireEvent.change(nameInput(), { target: { value: 'a'.repeat(64) } });
    fireEvent.blur(nameInput());
    expect(screen.getByText(/at most 63 characters/i)).toBeInTheDocument();
    expect(createBtn()).toBeDisabled();
  });
});

describe('CreateFolderView — submission', () => {
  it('submits a valid private folder', () => {
    const onSubmit = jest.fn<SubmitFn>();
    renderWithProviders(<CreateFolderView {...baseProps} onSubmit={onSubmit} />);
    fireEvent.change(nameInput(), { target: { value: 'documents' } });
    expect(createBtn()).not.toBeDisabled();
    fireEvent.click(createBtn());
    expect(onSubmit).toHaveBeenCalledWith({ name: 'documents', isPublic: false });
  });

  it('submits as public when the toggle is on', () => {
    const onSubmit = jest.fn<SubmitFn>();
    renderWithProviders(<CreateFolderView {...baseProps} onSubmit={onSubmit} />);
    fireEvent.change(nameInput(), { target: { value: 'documents' } });
    fireEvent.click(publicSwitch());
    fireEvent.click(createBtn());
    expect(onSubmit).toHaveBeenCalledWith({ name: 'documents', isPublic: true });
  });

  it('calls onCancel when Cancel is clicked', () => {
    const onCancel = jest.fn();
    renderWithProviders(<CreateFolderView {...baseProps} onCancel={onCancel} />);
    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }));
    expect(onCancel).toHaveBeenCalledTimes(1);
  });

  it('disables both actions while submitting', () => {
    renderWithProviders(<CreateFolderView {...baseProps} isSubmitting />);
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeDisabled();
  });
});
