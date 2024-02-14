import { useMemo } from "react";

import Table from "@/components/Table";
import { Tag, Text } from "@chakra-ui/react";

import {
  ConnectorAttributes,
  ConnectorListResponse,
  ConnectorTableColumnFields,
} from "../../types";
import moment from "moment";

import { CONNECTOR_LIST_COLUMNS } from "@/views/Connectors/constant";
import EntityItem from "@/components/EntityItem";
import Loader from "@/components/Loader";

type TableItem = {
  field: ConnectorTableColumnFields;
  attributes: ConnectorAttributes;
};

type TableRow = {
  id: string;
  connector: unknown;
};

type DestinationTableProps = {
  handleOnRowClick: (args: TableRow) => void;
  destinationData: ConnectorListResponse;
  isLoading?: boolean;
};

const TableItem = ({ field, attributes }: TableItem): JSX.Element => {
  switch (field) {
    case "name":
      return (
        <Text size="sm" fontWeight={600} color="black.500" letterSpacing="-0.14px">
          {attributes.name}
        </Text>
      );
    case "icon":
      return (
        <EntityItem
          icon={attributes?.[field]}
          name={attributes?.connector_name}
        />
      );

    case "updated_at":
      return (
        <Text
          size='sm'
          color='gray.700'
          fontWeight={500}
        >
          {moment(attributes?.updated_at).format('DD/MM/YYYY')}
        </Text>
      );

    case "status":
      return (
        <Tag
          colorScheme='teal'
          size='xs'
          bgColor='success.100'
          paddingX={2}
          fontWeight={600}
          borderColor='success.300'
          borderWidth='1px'
          borderStyle='solid'
          height='22px'
          borderRadius='4px'
        >
          <Text size='xs' fontWeight='semibold' color='success.600'>
            Active
          </Text>
        </Tag>
      );

    default:
      return <Text size="xs">{attributes?.[field]}</Text>;
  }
};

const DestinationsTable = ({
  handleOnRowClick,
  destinationData,
  isLoading,
}: DestinationTableProps): JSX.Element | null => {
  const connectors = destinationData?.data;

  const tableData = useMemo(() => {
    const rows = (connectors ?? [])?.map((connector) => {
      const { id, attributes } = connector;
      return CONNECTOR_LIST_COLUMNS.reduce(
        (acc, { key }) => ({
          [key]: <TableItem field={key} attributes={attributes} />,
          id,
          connector,
          ...acc,
        }),
        {}
      );
    });

    return {
      columns: CONNECTOR_LIST_COLUMNS,
      data: rows,
    };
  }, [destinationData]);

  if (!connectors || isLoading) {
    return <Loader />;
  }

  return <Table data={tableData} onRowClick={handleOnRowClick} />;
};

export default DestinationsTable;
