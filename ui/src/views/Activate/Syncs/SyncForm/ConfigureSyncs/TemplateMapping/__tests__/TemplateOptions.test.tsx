import { render, fireEvent } from '@testing-library/react';
import TemplateOptions from '../TemplateOptions';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';

describe('TemplateOptions component', () => {
<<<<<<< HEAD:ui/src/views/Activate/Syncs/SyncForm/ConfigureSyncs/TemplateMapping/__tests__/TemplateOptions.test.tsx
  const columnOptions = ['Column1', 'Column2', 'Column3'];
  const filterOptions = ['Filter1', 'Filter2', 'Filter3'];
  const variableOptions = ['Variable1', 'Variable2'];
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
            variable: {
              Variable1: { description: 'Description 1' },
              Variable2: { description: 'Description 2' },
            },
          },
        },
      },
    },
  };
=======
  const columnOptions = [
    { name: 'Column1', value: 'Column1', description: 'Description 1' },
    { name: 'Column2', value: 'Column2', description: 'Description 2' },
    { name: 'Column3', value: 'Column3', description: 'Description 3' },
  ];
  const filterOptions = [
    { name: 'Filter1', value: 'Filter1', description: 'Description 1' },
    { name: 'Filter2', value: 'Filter2', description: 'Description 2' },
    { name: 'Filter3', value: 'Filter3', description: 'Description 3' },
  ];
  const variableOptions = [
    { name: 'Variable1', value: 'Variable1', description: 'Description 1' },
    { name: 'Variable2', value: 'Variable2', description: 'Description 2' },
  ];
>>>>>>> d0c54bf0 (fix(CE): remove catalog mapping prop):ui/src/components/TemplateMappingOptions/__tests__/TemplateOptions.test.tsx

  test('renders TemplateOptions component with default tab and column options', () => {
    const { getByText, getByPlaceholderText } = render(
      <TemplateOptions
        columnOptions={columnOptions}
        variableOptions={variableOptions}
        filterOptions={filterOptions}
        selectedTemplate=''
        setSelectedTemplate={() => {}}
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
        variableOptions={variableOptions}
        filterOptions={filterOptions}
        selectedTemplate=''
        setSelectedTemplate={setSelectedTemplate}
      />,
    );

    // Click on "Variable" tab
    fireEvent.click(getByText('Variable'));

    // Variable tab should be active
    expect(getByText('Variable1')).toBeInTheDocument();
  });
});
