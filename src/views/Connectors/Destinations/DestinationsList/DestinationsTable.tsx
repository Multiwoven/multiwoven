import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";

import Table from "@/components/Table";
import { Badge, Box, Image, Spinner, Text } from "@chakra-ui/react";

import { ConnectorAttributes, ConnectorTableColumnFields } from "../../types";
import moment from "moment";

import { getUserConnectors } from "@/services/connectors";
import {
  DESTINATIONS_LIST_QUERY_KEY,
  CONNECTOR_LIST_COLUMNS,
} from "@/views/Connectors/constant";

type TableItem = {
  field: ConnectorTableColumnFields;
  attributes: ConnectorAttributes;
};

type DestinationTableProps = {
  handleOnRowClick: (args: Record<"id", string>) => void;
};

const TableItem = ({ field, attributes }: TableItem): JSX.Element => {
  switch (field) {
    case "icon":
      return (
        <Box display="flex" alignItems="center">
          <Box
            height="40px"
            width="40px"
            marginRight="10px"
            borderWidth="thin"
            padding="5px"
            borderRadius="8px"
          >
            <Image
              src={`/src/assets/icons/${attributes?.[field]}`}
              alt="destination icon"
              maxHeight="100%"
            />
          </Box>
          <Text>{attributes?.connector_name}</Text>
        </Box>
      );

    case "updated_at":
      return <Text>{moment(attributes?.updated_at).format("DD/MM/YYYY")}</Text>;

    case "status":
      return (
        <Badge colorScheme="green" variant="outline">
          Active
        </Badge>
      );

    default:
      return <Text>{attributes?.[field]}</Text>;
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
    const rows = (connectors ?? [])?.map(({ attributes, id }) => {
      return CONNECTOR_LIST_COLUMNS.reduce(
        (acc, { key }) => ({
          [key]: <TableItem field={key} attributes={attributes} />,
          id,
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
