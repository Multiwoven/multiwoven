import { render, screen, fireEvent } from '@testing-library/react';
import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { Formik, Form } from 'formik';
import { ChakraProvider } from '@chakra-ui/react';
import { ColumnsView } from '../ColumnsView';
import type { FormValues } from '../../NewVectorTableDrawer';

// Mock CustomSelect component
jest.mock('@/components/CustomSelect/CustomSelect', () => ({
  CustomSelect: ({ value, onChange, children }: any) => (
    <select data-testid='custom-select' value={value} onChange={(e) => onChange(e.target.value)}>
      {children}
    </select>
  ),
}));

jest.mock('@/components/CustomSelect/Option', () => ({
  Option: ({ value, children }: any) => <option value={value}>{children}</option>,
}));

// Mock generateSqlFromColumns
jest.mock('../../utils/sqlSchemaUtils', () => ({
  generateSqlFromColumns: jest.fn((tableName: string, columns: any[]) => {
    if (!tableName || columns.length === 0) return '';
    const colDefs = columns
      .filter((c) => c.name)
      .map((c) => `${c.name} ${c.dataType.toUpperCase()}`)
      .join(', ');
    return `CREATE TABLE ${tableName} (${colDefs});`;
  }),
}));

const renderWithFormik = (
  initialValues: FormValues,
  mockSetFieldValue: jest.Mock,
  mockHandleChange: jest.Mock,
) => {
  return render(
    <ChakraProvider>
      <Formik initialValues={initialValues} onSubmit={jest.fn()}>
        {({ values, handleChange }) => (
          <Form>
            <ColumnsView
              values={values}
              handleChange={(e) => {
                handleChange(e);
                mockHandleChange(e);
              }}
              setFieldValue={mockSetFieldValue}
            />
          </Form>
        )}
      </Formik>
    </ChakraProvider>,
  );
};

describe('ColumnsView', () => {
  const mockSetFieldValue = jest.fn();
  const mockHandleChange = jest.fn();

  const defaultValues: FormValues = {
    tableName: 'test_table',
    columns: [
      { name: 'id', dataType: 'int8', isPrimary: true, isNull: false },
      { name: 'name', dataType: 'text', isPrimary: false, isNull: true },
    ],
    sqlSchema: 'CREATE TABLE test_table (id INT8 PRIMARY KEY, name TEXT);',
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Table Name Field', () => {
    it('exposes stable test ids for hosted data store new table form controls', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      expect(screen.getByTestId('data-store-table-name-input')).toBeInTheDocument();
      expect(screen.getByTestId('data-store-column-name-input-0')).toBeInTheDocument();
      expect(screen.getByTestId('data-store-column-name-input-1')).toBeInTheDocument();
      expect(screen.getByTestId('data-store-add-column-button')).toBeInTheDocument();
    });

    it('renders table name input with label', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      expect(screen.getByText('Table Name')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('Enter table name')).toBeInTheDocument();
    });

    it('displays current table name value', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const input = screen.getByPlaceholderText('Enter table name');
      expect(input).toHaveValue('test_table');
    });

    it('sanitizes table name input (removes spaces and special characters)', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const input = screen.getByPlaceholderText('Enter table name');
      fireEvent.change(input, { target: { value: 'my table!@#$' } });

      // The sanitized value should be passed to setFieldValue
      expect(mockSetFieldValue).toHaveBeenCalledWith('tableName', 'my_table');
    });

    it('updates SQL schema when table name changes', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const input = screen.getByPlaceholderText('Enter table name');
      fireEvent.change(input, { target: { value: 'new_table' } });

      expect(mockSetFieldValue).toHaveBeenCalledWith(
        'sqlSchema',
        expect.stringContaining('new_table'),
      );
    });

    it('converts spaces to underscores in table name', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const input = screen.getByPlaceholderText('Enter table name');
      fireEvent.change(input, { target: { value: 'my new table' } });

      expect(mockSetFieldValue).toHaveBeenCalledWith('tableName', 'my_new_table');
    });
  });

  describe('Column Headers', () => {
    it('renders all column headers', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      expect(screen.getByText('Column Name')).toBeInTheDocument();
      expect(screen.getByText('Data Type')).toBeInTheDocument();
      expect(screen.getByText('Primary')).toBeInTheDocument();
      expect(screen.getByText('NULL')).toBeInTheDocument();
    });
  });

  describe('Column Rows', () => {
    it('renders correct number of column rows', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const columnInputs = screen.getAllByPlaceholderText('column_name');
      expect(columnInputs).toHaveLength(2);
    });

    it('displays column name values', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const columnInputs = screen.getAllByPlaceholderText('column_name');
      expect(columnInputs[0]).toHaveValue('id');
      expect(columnInputs[1]).toHaveValue('name');
    });

    it('displays column data types in select', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const selects = screen.getAllByTestId('custom-select');
      expect(selects[0]).toHaveValue('int8');
      expect(selects[1]).toHaveValue('text');
    });
  });

  describe('Primary Key Checkbox', () => {
    it('checks primary key checkbox for primary column', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const checkboxes = screen.getAllByRole('checkbox');
      // First column is primary (checkboxes: [primary, null, primary, null])
      expect(checkboxes[0]).toBeChecked(); // id is primary
      expect(checkboxes[2]).not.toBeChecked(); // name is not primary
    });

    it('disables primary key checkbox when column is nullable', () => {
      const valuesWithNullable: FormValues = {
        ...defaultValues,
        columns: [{ name: 'id', dataType: 'int8', isPrimary: false, isNull: true }],
      };

      renderWithFormik(valuesWithNullable, mockSetFieldValue, mockHandleChange);

      const checkboxes = screen.getAllByRole('checkbox');
      expect(checkboxes[0]).toBeDisabled(); // Primary checkbox disabled when isNull is true
    });

    it('disables primary key checkbox when another column already has primary key', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const checkboxes = screen.getAllByRole('checkbox');
      // Second column's primary checkbox should be disabled because first column has primary key
      expect(checkboxes[2]).toBeDisabled();
    });

    it('sets isNull to false when primary key is checked', () => {
      const valuesWithoutPrimary: FormValues = {
        ...defaultValues,
        columns: [{ name: 'id', dataType: 'int8', isPrimary: false, isNull: false }],
      };

      renderWithFormik(valuesWithoutPrimary, mockSetFieldValue, mockHandleChange);

      const checkboxes = screen.getAllByRole('checkbox');
      fireEvent.click(checkboxes[0]); // Click primary checkbox

      expect(mockSetFieldValue).toHaveBeenCalledWith('columns.0.isPrimary', true);
      expect(mockSetFieldValue).toHaveBeenCalledWith('columns.0.isNull', false);
    });
  });

  describe('Nullable Checkbox', () => {
    it('checks nullable checkbox for nullable column', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const checkboxes = screen.getAllByRole('checkbox');
      // Second pair of checkboxes for nullable
      expect(checkboxes[1]).not.toBeChecked(); // id is not nullable
      expect(checkboxes[3]).toBeChecked(); // name is nullable
    });

    it('disables nullable checkbox when column is primary key', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const checkboxes = screen.getAllByRole('checkbox');
      // First column's nullable checkbox should be disabled because it's primary
      expect(checkboxes[1]).toBeDisabled();
    });

    it('sets isPrimary to false when nullable is checked', () => {
      const valuesWithPrimary: FormValues = {
        ...defaultValues,
        columns: [{ name: 'id', dataType: 'int8', isPrimary: false, isNull: false }],
      };

      renderWithFormik(valuesWithPrimary, mockSetFieldValue, mockHandleChange);

      const checkboxes = screen.getAllByRole('checkbox');
      fireEvent.click(checkboxes[1]); // Click nullable checkbox

      expect(mockSetFieldValue).toHaveBeenCalledWith('columns.0.isNull', true);
      expect(mockSetFieldValue).toHaveBeenCalledWith('columns.0.isPrimary', false);
    });
  });

  describe('Add Column Button', () => {
    it('renders Add column button', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      expect(screen.getByText('Add column')).toBeInTheDocument();
    });
  });

  describe('Data Type Selection', () => {
    it('updates column data type and SQL schema when selection changes', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const selects = screen.getAllByTestId('custom-select');
      fireEvent.change(selects[1], { target: { value: 'vector' } });

      expect(mockSetFieldValue).toHaveBeenCalledWith('columns.1.dataType', 'vector');
      expect(mockSetFieldValue).toHaveBeenCalledWith('sqlSchema', expect.any(String));
    });
  });

  describe('SQL Schema Updates', () => {
    it('updates SQL schema when column name changes', () => {
      renderWithFormik(defaultValues, mockSetFieldValue, mockHandleChange);

      const columnInputs = screen.getAllByPlaceholderText('column_name');
      fireEvent.change(columnInputs[0], { target: { value: 'new_id' } });

      expect(mockSetFieldValue).toHaveBeenCalledWith(
        'sqlSchema',
        expect.stringContaining('new_id'),
      );
    });
  });

  describe('Empty State', () => {
    it('renders correctly with no columns', () => {
      const emptyValues: FormValues = {
        tableName: 'empty_table',
        columns: [],
        sqlSchema: '',
      };

      renderWithFormik(emptyValues, mockSetFieldValue, mockHandleChange);

      expect(screen.getByText('Add column')).toBeInTheDocument();
      expect(screen.queryAllByPlaceholderText('column_name')).toHaveLength(0);
    });
  });
});
