import { useQuery } from "@tanstack/react-query";
import { getUserConnectors } from "@/services/common";
import ConnectorTable from "@/components/ConnectorTable";
import { Box } from "@chakra-ui/react";
import { FiPlus } from "react-icons/fi";
import TopBar from "@/components/TopBar";
import { Outlet, useNavigate } from "react-router-dom";
import { SOURCES_LIST_QUERY_KEY } from "@/views/Connectors/constant";

const SourcesList = (): JSX.Element | null => {
  const { data } = useQuery({
    queryKey: SOURCES_LIST_QUERY_KEY,
    queryFn: () => getUserConnectors("Source"),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const connectors = data?.data;

  const navigate = useNavigate();

  if (!connectors) return null;

  return (
    <Box width="100%">
      <TopBar
        name={"Sources"}
        ctaName="Add Sources"
        ctaIcon={<FiPlus color="gray.100" />}
        onCtaClicked={() => navigate("new")}
        isCtaVisible
      />
      <ConnectorTable payload={connectors.data} />
      <Outlet />
    </Box>
  );
};

export default SourcesList;
