import { render, fireEvent } from '@testing-library/react';
import { expect } from '@jest/globals';
import BaseModal from '@/components/BaseModal';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';

describe('BaseModal', () => {
  it('should open the modal when openModal is true', () => {
    const setModalOpen = jest.fn();
    const { getByText } = render(
      <BaseModal
        openModal={true}
        setModalOpen={setModalOpen}
        title='Test Title'
        footer={<div>Footer Content</div>}
      >
        <div>Body Content</div>
      </BaseModal>,
    );
    expect(getByText('Test Title')).toBeInTheDocument();
  });

  it('renders ReactNode title inside the header', () => {
    const setModalOpen = jest.fn();
    const { getByText } = render(
      <BaseModal
        openModal
        setModalOpen={setModalOpen}
        title={<span>Rich modal title</span>}
        footer={<div>Footer Content</div>}
      >
        <div>Body Content</div>
      </BaseModal>,
    );
    expect(getByText('Rich modal title')).toBeInTheDocument();
  });

  it('should not open the modal when openModal is false', () => {
    const setModalOpen = jest.fn();
    const { queryByText } = render(
      <BaseModal
        openModal={false}
        setModalOpen={setModalOpen}
        title='Test Title'
        footer={<div>Footer Content</div>}
      >
        <div>Body Content</div>
      </BaseModal>,
    );
    expect(queryByText('Test Title')).not.toBeInTheDocument();
  });

  it('should close the modal when onClose is triggered', () => {
    const setModalOpen = jest.fn();
    const { getByRole } = render(
      <BaseModal
        openModal={true}
        setModalOpen={setModalOpen}
        title='Test Title'
        footer={<div>Footer Content</div>}
      >
        <div>Body Content</div>
      </BaseModal>,
    );
    fireEvent.click(getByRole('button', { name: /close/i }));
    expect(setModalOpen).toHaveBeenCalledWith(false);
  });

  it('applies contentDataTestId and closeButtonDataTestId when provided', () => {
    const setModalOpen = jest.fn();
    const { getByTestId } = render(
      <BaseModal
        openModal
        setModalOpen={setModalOpen}
        title='Test Title'
        footer={<div>Footer Content</div>}
        contentDataTestId='modal-content'
        closeButtonDataTestId='modal-close'
      >
        <div>Body Content</div>
      </BaseModal>,
    );
    expect(getByTestId('modal-content')).toBeInTheDocument();
    expect(getByTestId('modal-close')).toBeInTheDocument();
  });
});
