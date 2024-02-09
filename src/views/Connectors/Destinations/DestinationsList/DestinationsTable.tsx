import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";

import Table from "@/components/Table";
import { Badge, Box, Spinner, Text } from "@chakra-ui/react";

import { ConnectorAttributes, ConnectorTableColumnFields } from "../../types";
import moment from "moment";

import { getUserConnectors } from "@/services/connectors";
import {
  DESTINATIONS_LIST_QUERY_KEY,
  CONNECTOR_LIST_COLUMNS,
} from "@/views/Connectors/constant";
import EntityItem from "@/components/EntityItem";

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
};

const TableItem = ({ field, attributes }: TableItem): JSX.Element => {
  switch (field) {
    case "icon":
      return (
        <EntityItem
          icon={attributes?.[field]}
          name={attributes?.connector_name}
        />
      );

    case "updated_at":
      return <Text size='sm'>{moment(attributes?.updated_at).format("DD/MM/YYYY")}</Text>;

    case "status":
      return (
        <Badge colorScheme="green" variant="outline">
          Active
        </Badge>
      );

    default:
      return <Text size='sm'>{attributes?.[field]}</Text>;
  }
};

const DestinationsTable = ({
  handleOnRowClick,
}: DestinationTableProps): JSX.Element | null => {
  const { data, isLoading } = useQuery({
    queryKey: DESTINATIONS_LIST_QUERY_KEY,
    queryFn: () => getUserConnectors("destination"),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const connectors = data?.data;

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
  }, [data]);

  if (!connectors || isLoading) {
    return (
      <Box width="100%" display="flex" justifyContent="center">
        <Spinner
          thickness="4px"
          speed="0.65s"
          emptyColor="gray.200"
          color="blue.500"
          size="xl"
        />
      </Box>
    );
  }

  return <Table data={tableData} onRowClick={handleOnRowClick} />;
};

export default DestinationsTable;
