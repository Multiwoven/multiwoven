import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { Badge, Box, Image, Text } from "@chakra-ui/react";
import { FiPlus } from "react-icons/fi";
import TopBar from "@/components/TopBar";
import { useNavigate } from "react-router-dom";
import {
  SOURCES_LIST_QUERY_KEY,
  SOURCE_LIST_COLUMNS,
} from "@/views/Connectors/constant";
import Table from "@/components/Table";
import { getUserConnectors } from "@/services/connectors";
import { ConnectorAttributes, SourcesTableColumnFields } from "../../types";
import moment from "moment";
import ContentContainer from "@/components/ContentContainer";

type TableItem = {
  field: SourcesTableColumnFields;
  attributes: ConnectorAttributes;
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
              alt="source icon"
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

const SourcesList = (): JSX.Element | null => {
  const navigate = useNavigate();
  const { data } = useQuery({
    queryKey: SOURCES_LIST_QUERY_KEY,
    queryFn: () => getUserConnectors("Source"),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const connectors = data?.data;

  const tableData = useMemo(() => {
    const rows = (connectors ?? [])?.map(({ attributes, id }) => {
      return SOURCE_LIST_COLUMNS.reduce(
        (acc, { key }) => ({
          [key]: <TableItem field={key} attributes={attributes} />,
          id,
          ...acc,
        }),
        {}
      );
    });

    return {
      columns: SOURCE_LIST_COLUMNS,
      data: rows,
    };
  }, [data]);

  if (!connectors) return null;

  return (
    <Box width="100%" display="flex" flexDirection="column" alignItems="center">
      <ContentContainer>
        <TopBar
          name="Sources"
          ctaName="Add Sources"
          ctaIcon={<FiPlus color="gray.100" />}
          onCtaClicked={() => navigate("new")}
          ctaBgColor="orange.500"
          ctaColor="gray.900"
          ctaHoverBgColor="orange.400"
          isCtaVisible
        />
        <Table
          data={tableData}
          onRowClick={(row) => navigate(`/setup/sources/${row?.id}`)}
        />
      </ContentContainer>
    </Box>
  );
};

export default SourcesList;
