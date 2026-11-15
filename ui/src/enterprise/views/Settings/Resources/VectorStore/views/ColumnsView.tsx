import {
  Box,
  FormControl,
  FormLabel,
  Input,
  Checkbox,
  Flex,
  Icon,
  HStack,
  Text,
  Button,
} from '@chakra-ui/react';
import { FieldArray } from 'formik';
import { FiPlus, FiX, FiHash, FiType, FiCalendar } from 'react-icons/fi';
import { CustomSelect } from '@/components/CustomSelect/CustomSelect';
import { Option } from '@/components/CustomSelect/Option';
import { ColumnField, FormValues } from '../NewVectorTableDrawer';
import { generateSqlFromColumns } from '../utils/sqlSchemaUtils';

type ColumnsViewProps = {
  values: FormValues;
  handleChange: (e: React.ChangeEvent<any>) => void;
  setFieldValue: (field: string, value: any) => void;
};

/**
 * Helper to update SQL schema when columns or table name change
 */
const updateSqlSchema = (
  tableName: string,
  columns: ColumnField[],
  setFieldValue: (field: string, value: any) => void,
) => {
  const sql = generateSqlFromColumns(tableName, columns);
  setFieldValue('sqlSchema', sql);
};

const DATA_TYPES = [
  { value: 'int8', label: 'int8', icon: FiHash },
  { value: 'text', label: 'text', icon: FiType },
  { value: 'vector', label: 'vector', icon: FiHash },
  { value: 'timestamp', label: 'timestamp', icon: FiCalendar },
];

export const ColumnsView = ({ values, handleChange, setFieldValue }: ColumnsViewProps) => {
  // Find the index of the column that has primary key set (if any)
  const primaryKeyIndex = values.columns.findIndex((col) => col.isPrimary);
  const hasPrimaryKey = primaryKeyIndex !== -1;

  return (
    <>
      {/* Table Name Field */}
      <FormControl isRequired>
        <FormLabel fontWeight='semibold' fontSize='sm' mb='8px'>
          Table Name
        </FormLabel>
        <Input
          data-testid='data-store-table-name-input'
          name='tableName'
          value={values.tableName}
          onChange={(e) => {
            const sanitizedValue = e.target.value.replace(/ /g, '_').replace(/[^a-zA-Z0-9_]/g, '');
            setFieldValue('tableName', sanitizedValue);
            updateSqlSchema(sanitizedValue, values.columns, setFieldValue);
          }}
          placeholder='Enter table name'
          size='md'
          borderColor='gray.400'
        />
      </FormControl>

      {/* Column Headers */}
      <Box>
        <Flex gap='12px' mb='12px' alignItems='center'>
          <Box flex='1' minWidth='150px'>
            <Text fontSize='sm' fontWeight='semibold' color='black.500'>
              Column Name
            </Text>
          </Box>
          <Box flex='1' minWidth='150px'>
            <Text fontSize='sm' fontWeight='semibold' color='black.500'>
              Data Type
            </Text>
          </Box>
          <Box width='80px' textAlign='center'>
            <Text fontSize='sm' fontWeight='semibold' color='black.500'>
              Primary
            </Text>
          </Box>
          <Box width='70px' textAlign='center'>
            <Text fontSize='sm' fontWeight='semibold' color='black.500'>
              NULL
            </Text>
          </Box>
          <Box width='40px' />
        </Flex>

        {/* Column Rows */}
        <FieldArray name='columns'>
          {({ push, remove }) => (
            <>
              {values.columns.map((column, index) => (
                <Flex key={index} gap='12px' mb='12px' alignItems='center'>
                  <Box flex='1' minWidth='150px'>
                    <Input
                      data-testid={`data-store-column-name-input-${index}`}
                      name={`columns.${index}.name`}
                      value={column.name}
                      onChange={(e) => {
                        handleChange(e);
                        const updatedColumns = [...values.columns];
                        updatedColumns[index] = { ...updatedColumns[index], name: e.target.value };
                        updateSqlSchema(values.tableName, updatedColumns, setFieldValue);
                      }}
                      placeholder='column_name'
                      fontSize='14px'
                      borderColor='gray.400'
                    />
                  </Box>
                  <Box flex='1' minWidth='150px'>
                    <CustomSelect
                      value={column.dataType}
                      onChange={(value) => {
                        setFieldValue(`columns.${index}.dataType`, value);
                        const updatedColumns = [...values.columns];
                        updatedColumns[index] = { ...updatedColumns[index], dataType: value || '' };
                        updateSqlSchema(values.tableName, updatedColumns, setFieldValue);
                      }}
                    >
                      {DATA_TYPES.map((type) => (
                        <Option key={type.value} value={type.value}>
                          <HStack gap='8px'>
                            <Icon as={type.icon} h={'16px'} w={'16px'} color='gray.600' />
                            <Text size='sm' fontWeight={400}>
                              {type.label}
                            </Text>
                          </HStack>
                        </Option>
                      ))}
                    </CustomSelect>
                  </Box>
                  <Box width='80px' display='flex' justifyContent='center'>
                    <Checkbox
                      isChecked={column.isPrimary}
                      onChange={(e) => {
                        const checked = e.target.checked;
                        setFieldValue(`columns.${index}.isPrimary`, checked);
                        if (checked) {
                          setFieldValue(`columns.${index}.isNull`, false);
                        }
                        const updatedColumns = [...values.columns];
                        updatedColumns[index] = {
                          ...updatedColumns[index],
                          isPrimary: checked,
                          isNull: checked ? false : updatedColumns[index].isNull,
                        };
                        updateSqlSchema(values.tableName, updatedColumns, setFieldValue);
                      }}
                      height={'16px'}
                      borderColor='info.200'
                      isDisabled={column.isNull || (hasPrimaryKey && !column.isPrimary)}
                    />
                  </Box>
                  <Box width='70px' display='flex' justifyContent='center'>
                    <Checkbox
                      isChecked={column.isNull}
                      onChange={(e) => {
                        const checked = e.target.checked;
                        setFieldValue(`columns.${index}.isNull`, checked);
                        if (checked) {
                          setFieldValue(`columns.${index}.isPrimary`, false);
                        }
                        const updatedColumns = [...values.columns];
                        updatedColumns[index] = {
                          ...updatedColumns[index],
                          isNull: checked,
                          isPrimary: checked ? false : updatedColumns[index].isPrimary,
                        };
                        updateSqlSchema(values.tableName, updatedColumns, setFieldValue);
                      }}
                      height={'16px'}
                      borderColor='info.200'
                      isDisabled={column.isPrimary}
                    />
                  </Box>
                  <Box width='40px' display='flex' justifyContent='center'>
                    <Icon
                      as={FiX}
                      color='gray.600'
                      onClick={() => {
                        remove(index);
                        const updatedColumns = values.columns.filter((_, i) => i !== index);
                        updateSqlSchema(values.tableName, updatedColumns, setFieldValue);
                      }}
                      cursor='pointer'
                    />
                  </Box>
                </Flex>
              ))}

              <Button
                data-testid='data-store-add-column-button'
                type='button'
                leftIcon={<FiPlus />}
                variant='outline'
                onClick={() => {
                  const newColumn: ColumnField = {
                    name: '',
                    dataType: 'text',
                    isPrimary: false,
                    isNull: false,
                  };
                  push(newColumn);
                  // Note: SQL will update when the user fills in the column name
                }}
                mt='16px'
                w='fit-content'
                minWidth={0}
              >
                <Text fontWeight={700} size='xs'>
                  Add column
                </Text>
              </Button>
            </>
          )}
        </FieldArray>
      </Box>
    </>
  );
};
