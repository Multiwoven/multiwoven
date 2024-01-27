import { useQuery } from "@tanstack/react-query";
import ConnectorTable from "@/components/ConnectorTable";
import { Box } from "@chakra-ui/react";
import { FiPlus } from "react-icons/fi";
import TopBar from "@/components/TopBar";
import { Outlet, useNavigate } from "react-router-dom";
import {
  SOURCES_LIST_QUERY_KEY,
  SOURCE_LIST_COLUMNS,
} from "@/views/Connectors/constant";
import Table from "@/components/Table";
import { getUserConnectors } from "@/services/connectors";
import { useMemo } from "react";

const SourcesList = (): JSX.Element | null => {
  const { data } = useQuery({
    queryKey: SOURCES_LIST_QUERY_KEY,
    queryFn: () => getUserConnectors("Source"),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const connectors = data?.data;

  const tableData = useMemo(() => {
    const rows = connectors?.map(({ attributes }) => {
      return SOURCE_LIST_COLUMNS.reduce(
        (acc, { key }) => ({
          [key]: attributes?.[key],
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

  const navigate = useNavigate();

  if (!connectors) return null;

  return (
    <Box width="100%">
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
      <Box maxWidth="1300px">
        <Table data={tableData} onRowClick={(row) => console.log(row)} />
      </Box>
      <Outlet />
    </Box>
  );
};

export default SourcesList;
