import type { ComponentProps } from 'react';
import { render, screen } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { MemoryRouter } from 'react-router-dom';
import FormFooter from '../FormFooter';

const renderFormFooter = (props: ComponentProps<typeof FormFooter>) =>
  render(
    <MemoryRouter>
      <ChakraProvider>
        <FormFooter {...props} />
      </ChakraProvider>
    </MemoryRouter>,
  );

describe('FormFooter', () => {
  it('exposes stepped-form data-testid derived from cta label for Continue', () => {
    renderFormFooter({
      ctaName: 'Continue',
      isContinueCtaRequired: true,
    });
    expect(screen.getByTestId('stepped-form-continue')).toHaveTextContent('Continue');
  });

  it('normalizes cta label to kebab-case for data-testid', () => {
    renderFormFooter({
      ctaName: 'Save Changes',
      isContinueCtaRequired: true,
    });
    expect(screen.getByTestId('stepped-form-save-changes')).toHaveTextContent('Save Changes');
  });

  it('collapses internal spaces in cta name for data-testid', () => {
    renderFormFooter({
      ctaName: 'Save  Draft',
      isContinueCtaRequired: true,
    });
    expect(screen.getByTestId('stepped-form-save-draft')).toBeInTheDocument();
  });

  it('does not render primary CTA when isContinueCtaRequired is false', () => {
    renderFormFooter({
      ctaName: 'Continue',
      isContinueCtaRequired: false,
    });
    expect(screen.queryByTestId('stepped-form-continue')).not.toBeInTheDocument();
  });
});
