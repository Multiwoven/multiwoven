import { render, fireEvent } from '@testing-library/react';
import StaticOptions from '../StaticOptions';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { expect } from '@jest/globals';

describe('StaticOptions component', () => {
  const staticValues = ['string', 'boolean', 'number', 'null'];

  test('should render StaticOptions component with all the options', () => {
    const setSelectedStaticOptionValue = jest.fn();
    const { getByText } = render(
      <StaticOptions
        staticValues={staticValues}
        selectedStaticOptionValue=''
        setSelectedStaticOptionValue={setSelectedStaticOptionValue}
      />,
    );

    expect(getByText('string')).toBeInTheDocument();
    expect(getByText('boolean')).toBeInTheDocument();
    expect(getByText('number')).toBeInTheDocument();
    expect(getByText('null')).toBeInTheDocument();
  });

  test('should render true/false radio buttons when boolean option is selected', () => {
    const setSelectedStaticOptionValue = jest.fn();
    const { getByLabelText, getByText } = render(
      <StaticOptions
        staticValues={staticValues}
        selectedStaticOptionValue=''
        setSelectedStaticOptionValue={setSelectedStaticOptionValue}
      />,
    );

    // Click on the boolean option
    fireEvent.click(getByLabelText('boolean'));

    // Assert that true/false radio buttons are rendered
    expect(getByText('True')).toBeInTheDocument();
    expect(getByText('False')).toBeInTheDocument();
  });

  test('should render input box and text when string option is selected', () => {
    const setSelectedStaticOptionValue = jest.fn();
    const { getByLabelText, getByText } = render(
      <StaticOptions
        staticValues={staticValues}
        selectedStaticOptionValue=''
        setSelectedStaticOptionValue={setSelectedStaticOptionValue}
      />,
    );

    // Click on the string option
    fireEvent.click(getByLabelText('string'));

    expect(
      getByText('Strings can include any combination of numbers, letters, and special characters.'),
    ).toBeInTheDocument();
  });

  test('should render null text when null option is selected', () => {
    const setSelectedStaticOptionValue = jest.fn();
    const { getByLabelText, getByText } = render(
      <StaticOptions
        staticValues={staticValues}
        selectedStaticOptionValue=''
        setSelectedStaticOptionValue={setSelectedStaticOptionValue}
      />,
    );

    // Click on the null option
    fireEvent.click(getByLabelText('null'));

    expect(getByText('A null value be synced to this destination field.')).toBeInTheDocument();
  });
});
