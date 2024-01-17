import { useQuery } from "@tanstack/react-query";
import { getUserConnectors } from "@/services/common";
import ConnectorTable from "@/components/ConnectorTable";
import { Box } from "@chakra-ui/react";
import { FiPlus } from "react-icons/fi";
import TopBar from "@/components/TopBar";
import { useNavigate } from "react-router-dom";

const SourcesList = () => {
  const { data } = useQuery({
    queryKey: ["connectors", "source"],
    queryFn: () => getUserConnectors("Source"),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const navigate = useNavigate();
  const connectors = data?.data;

  if (!connectors) return null;

  return (
    <Box width="100%">
      <TopBar
        name={"Sources"}
        ctaName="Add New"
        ctaIcon={<FiPlus color="gray.100" />}
        onCtaClicked={() => navigate("new")}
        isCtaVisible
      />
      <ConnectorTable payload={connectors} />
    </Box>
  );
};

export default SourcesList;
