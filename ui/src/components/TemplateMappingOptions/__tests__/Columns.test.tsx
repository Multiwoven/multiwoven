import { render, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';

import Columns from '../Columns';
import { expect } from '@jest/globals';

import { OPTION_TYPE } from '../types';

export const columnOptions = [
  { name: 'Column 1', value: 'Column 1', description: 'Description 1' },
  { name: 'Column 2', value: 'Column 2', description: 'Description 2' },
  { name: 'Column 3', value: 'Column 3', description: 'Description 3' },
];
export const catalogMappingMock = {
  data: {
    configurations: {
      catalog_mapping_types: {
        static: {},
        template: {
          filter: {
            'Column 1': { description: 'Description 1' },
            'Column 2': { description: 'Description 2' },
            'Column 3': { description: 'Description 3' },
          },
          variable: {},
        },
      },
    },
  },
};

describe('Columns component', () => {
  test('renders column options', () => {
    const { getByText } = render(
      <Columns
        columnOptions={columnOptions}
        showFilter={false}
        showDescription={false}
        fieldType='model'
        templateColumnType={OPTION_TYPE.FILTER}
      />,
    );

    expect(getByText('Column 1')).toBeInTheDocument();
    expect(getByText('Column 2')).toBeInTheDocument();
    expect(getByText('Column 3')).toBeInTheDocument();
  });

  test('renders filtered column options based on search term', () => {
    const { getByPlaceholderText, getByText } = render(
      <Columns
        columnOptions={columnOptions}
        showFilter={true}
        showDescription={false}
        fieldType='model'
        templateColumnType={OPTION_TYPE.FILTER}
      />,
    );

    const input = getByPlaceholderText('Search Columns');

    fireEvent.change(input, { target: { value: 'Column 1' } });

    expect(getByText('Column 1')).toBeInTheDocument();
  });

  test('renders description for column options', () => {
    const { getByText } = render(
      <Columns
        columnOptions={columnOptions}
        catalogMapping={catalogMappingMock}
        showFilter={false}
        showDescription={true}
        fieldType='model'
        templateColumnType={OPTION_TYPE.FILTER}
      />,
    );

    expect(getByText('Description 1')).toBeInTheDocument();
    expect(getByText('Description 2')).toBeInTheDocument();
    expect(getByText('Description 3')).toBeInTheDocument();
  });

  test('renders no results found message when no columns match search term', () => {
    const { getByPlaceholderText, getByText } = render(
      <Columns
        columnOptions={columnOptions}
        showFilter={true}
        showDescription={false}
        fieldType='model'
        templateColumnType={OPTION_TYPE.FILTER}
      />,
    );

    const input = getByPlaceholderText('Search Columns');

    fireEvent.change(input, { target: { value: 'Column 4' } });

    expect(getByText('No results found')).toBeInTheDocument();
  });
});
