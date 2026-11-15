import {
  Drawer,
  DrawerHeader,
  DrawerOverlay,
  DrawerContent,
  DrawerCloseButton,
  Text,
  DrawerBody,
  Button,
  DrawerFooter,
  Box,
} from '@chakra-ui/react';
import { useState } from 'react';
import { Formik, Form } from 'formik';
import { useQueryClient } from '@tanstack/react-query';
import { ColumnsView, SqlSchemaView } from './views';
import AlertBox from '@/components/Alerts';
import useHostedStoreMutations from '@/enterprise/hooks/mutations/useHostedStoreMutations';
import { HostedDataStoreTableResponse } from '@/enterprise/services/types';
import { useAPIErrorsToast } from '@/hooks/useErrorToast';
import { generateSqlFromColumns } from './utils/sqlSchemaUtils';

export type ColumnField = {
  name: string;
  dataType: string;
  isPrimary: boolean;
  isNull: boolean;
};

export type FormValues = {
  tableName: string;
  columns: ColumnField[];
  sqlSchema: string;
};

type NewVectorTableDrawerProps = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  isEditable?: boolean;
  dataStoreId: string;
  selectedTable?: HostedDataStoreTableResponse | null;
};

const NewVectorTableDrawer = ({
  isOpen,
  onClose,
  title,
  isEditable = true,
  dataStoreId,
  selectedTable,
}: NewVectorTableDrawerProps) => {
  const { createHostedDataStoreTableMutation, updateHostedDataStoreTableMutation } =
    useHostedStoreMutations();
  const apiErrorToast = useAPIErrorsToast();
  const queryClient = useQueryClient();
  const templateAPIResponse = {
    template_id: 'vector_store_hosted_connector',
    name: 'Vector Store',
    description: 'An all-in-one database solution, optimized for vector and AI workflows.',
    database_type: 'vector_db',
    configuration_schema: {
      json_schema: [
        {
          table_name: 'document_vector_embeddings',
          columns: [
            {
              name: 'id',
              nullable: false,
              data_type: 'int8',
              primary_key: true,
            },
            {
              name: 'text',
              nullable: false,
              data_type: 'text',
              primary_key: false,
            },
            {
              name: 'embedding',
              nullable: false,
              data_type: 'vector',
              primary_key: false,
            },
            {
              name: 'created_at',
              nullable: false,
              data_type: 'timestamp',
              primary_key: false,
            },
          ],
          sql_schema_script:
            'CREATE TABLE document_vector_embeddings (id INT8 PRIMARY KEY, text TEXT NOT NULL, embedding VECTOR NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL);',
        },
      ],
    },
  };

  const [isSqlSchemaOpen, setIsSqlSchemaOpen] = useState(false);

  // Generate initial values based on whether we're editing or creating
  const getInitialValues = (): FormValues => {
    if (selectedTable) {
      // Prefill with selected table data
      const schema = selectedTable.attributes.table_schema;
      const columns: ColumnField[] = Object.entries(schema.properties).map(([name, config]) => ({
        name,
        dataType: config.type.toLowerCase(),
        isPrimary: config.primary_key || false,
        isNull: !schema.required.includes(name),
      }));

      // Generate SQL schema using the utility function
      const sqlSchema = generateSqlFromColumns(selectedTable.attributes.name, columns);

      return {
        tableName: selectedTable.attributes.name,
        columns,
        sqlSchema,
      };
    }

    // Use template for new tables
    const templateColumns: ColumnField[] =
      templateAPIResponse.configuration_schema.json_schema[0].columns.map((column) => ({
        name: column.name,
        dataType: column.data_type,
        isPrimary: column.primary_key,
        isNull: column.nullable,
      }));

    const templateTableName = templateAPIResponse.configuration_schema.json_schema[0].table_name;

    return {
      tableName: templateTableName,
      columns: templateColumns,
      sqlSchema: generateSqlFromColumns(templateTableName, templateColumns),
    };
  };

  const initialValues = getInitialValues();

  const handleSubmit = async (values: FormValues) => {
    // Transform columns to the required payload format
    const properties: Record<string, { type: string; primary_key?: boolean }> = {};
    const required: string[] = [];

    values.columns.forEach((column) => {
      properties[column.name] = {
        type: column.dataType.toUpperCase(),
        ...(column.isPrimary && { primary_key: true }),
      };

      if (!column.isNull) {
        required.push(column.name);
      }
    });

    const payload = {
      hosted_data_store_table: {
        name: values.tableName,
        template_id: 'vector_store_hosted_connector',
        table_schema: {
          type: 'vector_db',
          properties,
          required,
        },
      },
    };

    let response;

    if (selectedTable) {
      // Update existing table
      response = await updateHostedDataStoreTableMutation.mutateAsync({
        dataStoreId,
        tableId: selectedTable.id,
        payload,
      });
    } else {
      // Create new table
      response = await createHostedDataStoreTableMutation.mutateAsync({
        dataStoreId,
        payload,
      });
    }

    if (response.data?.id) {
      // Refetch the data store tables list
      queryClient.invalidateQueries({
        queryKey: ['get-hosted-data-store-tables', dataStoreId],
      });
      onClose();
    }
    if (response.errors) {
      apiErrorToast(response.errors);
    }
  };

  return (
    <Drawer placement='right' onClose={onClose} isOpen={isOpen} size='lg'>
      <DrawerOverlay />
      <DrawerContent width='600px' maxHeight='100vh'>
        <DrawerCloseButton color='gray.600' />
        <DrawerHeader>
          <Text size='xl' fontWeight='bold' color='black.500'>
            {title}
          </Text>
        </DrawerHeader>
        <DrawerBody>
          {!isEditable && (
            <Box marginBottom='24px'>
              <AlertBox
                title=''
                description='This table can’t be modified because it’s part of an active sync. Disable the sync first to modify the table.'
                status='warning'
              />
            </Box>
          )}
          <Formik initialValues={initialValues} onSubmit={handleSubmit}>
            {({ values, handleChange, setFieldValue }) => (
              <Form id='new-vector-table-form'>
                <Box display='flex' flexDirection='column' gap='24px'>
                  {!isSqlSchemaOpen ? (
                    <ColumnsView
                      values={values}
                      handleChange={handleChange}
                      setFieldValue={setFieldValue}
                    />
                  ) : (
                    <SqlSchemaView
                      values={values}
                      setFieldValue={setFieldValue}
                      readOnly={!isEditable}
                    />
                  )}
                </Box>
              </Form>
            )}
          </Formik>
        </DrawerBody>
        <DrawerFooter
          gap='12px'
          borderTopWidth='1px'
          borderTopColor='gray.200'
          mt='auto'
          justifyContent='space-between'
        >
          <Button
            type='button'
            variant='outline'
            w='fit-content'
            onClick={() => setIsSqlSchemaOpen(!isSqlSchemaOpen)}
            isDisabled={!isEditable}
          >
            {isSqlSchemaOpen ? 'Define Columns' : 'Define SQL Schema'}
          </Button>
          <Box display='flex' gap='12px'>
            <Button type='button' variant='ghost' w='fit-content' onClick={onClose}>
              Cancel
            </Button>
            <Button
              data-testid='data-store-submit-button'
              w='fit-content'
              form='new-vector-table-form'
              type='submit'
              isDisabled={!isEditable}
              isLoading={
                createHostedDataStoreTableMutation.isPending ||
                updateHostedDataStoreTableMutation.isPending
              }
            >
              {selectedTable ? 'Update' : 'Create'}
            </Button>
          </Box>
        </DrawerFooter>
      </DrawerContent>
    </Drawer>
  );
};

export default NewVectorTableDrawer;
