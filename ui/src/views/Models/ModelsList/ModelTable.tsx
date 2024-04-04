import { APIData, ModelAttributes } from '@/services/models';
import Loader from '@/components/Loader';
import { ModelColumnFields } from '../types';
import EntityItem from '@/components/EntityItem';
import { Text } from '@chakra-ui/react';
import moment from 'moment';
import { useMemo } from 'react';
import { MODEL_TABLE_COLUMNS } from '../constants';
import Table from '@/components/Table';

type TableItem = {
  field: ModelColumnFields;
  data: ModelAttributes;
};

const TableItem = ({ field, data }: TableItem): JSX.Element | null | undefined => {
  switch (field) {
    case 'name':
      return <EntityItem icon={data.connector.icon} name={data.name} />;
    case 'query_type':
      switch (data.query_type) {
        case 'raw_sql':
          return (
            <Text size='sm' fontWeight='semibold'>
              SQL Query
            </Text>
          );
      }
      return <></>;

    case 'last_updated':
      return (
        <Text size='sm' fontWeight='medium'>
          {moment().format('DD/MM/YYYY')}
        </Text>
      );
  }
};

type TableRow = {
  id: string;
  model: unknown;
};

type ModelTableProps = {
  handleOnRowClick: (args: TableRow) => void;
  modelData: APIData;
  isLoading: boolean;
};

const ModelTable = ({ handleOnRowClick, modelData, isLoading }: ModelTableProps): JSX.Element => {
  const models = modelData?.data;
  const tableData = useMemo(() => {
    if (models && models?.length > 0) {
      const rows = models.map(({ attributes, id }) => {
        return MODEL_TABLE_COLUMNS.reduce(
          (acc, { key }) => ({
            [key]: <TableItem field={key} data={attributes} />,
            id,
            ...acc,
          }),
          {},
        );
      });

      return {
        columns: MODEL_TABLE_COLUMNS,
        data: rows,
      };
    }
  }, [modelData]);

  if (!models || isLoading) {
    return <Loader />;
  }

  return (
    <>
      {isLoading || !tableData ? (
        <Loader />
      ) : (
        <Table data={tableData} onRowClick={handleOnRowClick} />
      )}
    </>
  );
};

export default ModelTable;
