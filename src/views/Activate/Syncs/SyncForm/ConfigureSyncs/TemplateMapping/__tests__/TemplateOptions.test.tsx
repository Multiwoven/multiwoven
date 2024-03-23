import { render, fireEvent } from '@testing-library/react';
import TemplateOptions from '../TemplateOptions';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';

describe('TemplateOptions component', () => {
  const columnOptions = ['Column1', 'Column2', 'Column3'];
  const filterOptions = ['Filter1', 'Filter2', 'Filter3'];
  const catalogMapping = {
    data: {
      configurations: {
        catalog_mapping_types: {
          static: {},
          template: {
            filter: {
              Column1: { description: 'Description 1' },
              Column2: { description: 'Description 2' },
              Column3: { description: 'Description 3' },
            },
            variable: {},
          },
        },
      },
    },
  };

  test('renders TemplateOptions component with default tab and column options', () => {
    const { getByText, getByPlaceholderText } = render(
      <TemplateOptions
        columnOptions={columnOptions}
        filterOptions={filterOptions}
        selectedTemplate=''
        setSelectedTemplate={() => {}}
        catalogMapping={catalogMapping}
      />,
    );

    expect(getByText('Column')).toBeInTheDocument();
    expect(
      getByPlaceholderText(
        'Click on any variable/filter on the right to inject into liquid template',
      ),
    ).toBeInTheDocument();

    // Column options should be visible
    columnOptions.forEach((option) => {
      expect(getByText(option)).toBeInTheDocument();
    });
  });

  test('switches tabs and updates template accordingly', () => {
    const setSelectedTemplate = jest.fn();

    const { getByText } = render(
      <TemplateOptions
        columnOptions={columnOptions}
        filterOptions={filterOptions}
        selectedTemplate=''
        setSelectedTemplate={setSelectedTemplate}
        catalogMapping={catalogMapping}
      />,
    );

    // Click on "Variable" tab
    fireEvent.click(getByText('Variable'));

    // Variable tab should be active
    expect(getByText('Current Timestamp')).toBeInTheDocument();
  });
});
