import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, jest } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import type { BaseInputTemplateProps } from '@rjsf/utils';

jest.mock('@rjsf/chakra-ui/lib/utils', () => ({
  getChakra: () => ({}),
}));

import BaseInputTemplate from '../BaseInputTemplate';

const baseRegistry = {
  templates: {},
  widgets: {},
  rootSchema: {},
  schemaUtils: {
    getDisplayLabel: () => false,
  },
  globalUiOptions: {},
} as unknown as BaseInputTemplateProps['registry'];

describe('BaseInputTemplate', () => {
  it('sets connector-config-field test id for root_* ids', () => {
    const onChange = jest.fn();
    const onBlur = jest.fn();
    const onFocus = jest.fn();

    const props = {
      id: 'root_database_host',
      name: 'root_database_host',
      schema: { type: 'string' },
      uiSchema: {},
      value: '',
      label: 'Host',
      hideLabel: false,
      required: false,
      disabled: false,
      readonly: false,
      autofocus: false,
      placeholder: 'localhost',
      onChange,
      onBlur,
      onFocus,
      onChangeOverride: undefined,
      options: {},
      rawErrors: [],
      registry: baseRegistry,
    } as unknown as BaseInputTemplateProps;

    render(
      <ChakraProvider>
        <BaseInputTemplate {...props} />
      </ChakraProvider>,
    );

    const input = screen.getByTestId('connector-config-field-database_host');
    expect(input).toHaveAttribute('id', 'root_database_host');
    fireEvent.change(input, { target: { value: 'db.example.com' } });
    expect(onChange).toHaveBeenCalledWith('db.example.com');
  });
});
