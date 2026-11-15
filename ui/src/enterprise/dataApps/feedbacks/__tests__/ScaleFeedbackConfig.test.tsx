import '@testing-library/jest-dom';
import { render, screen } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import ScaleFeedbackConfig from '../ScaleFeedbackConfig';

describe('ScaleFeedbackConfig', () => {
  it('renders ScaleFeedbackConfig component correclty', () => {
    render(<ScaleFeedbackConfig />);
    expect(screen.getByTestId('scale-feedback-container')).toBeTruthy();
    expect(screen.getByTestId('scale-type-select')).toBeTruthy();
    expect(screen.getByTestId('scale-type-select')).toBeDisabled();
  });
});
