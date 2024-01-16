import { Box } from "@chakra-ui/react";
import TopBar from "@/components/TopBar";
import { useNavigate } from "react-router-dom";
import ConnectorTable from "@/components/ConnectorTable";
import { getUserConnectors } from "@/services/common";
import NoConnectors from "./NoConnectors";
import { ConnectorTypes } from "./types";
import { CONNECTORS } from "./constant";
import { FiPlus } from "react-icons/fi";
import { useQuery } from "@tanstack/react-query";

type ViewAllProps = {
  connectorType: ConnectorTypes;
};

const ViewAll = ({ connectorType }: ViewAllProps): JSX.Element | null => {
  const { data } = useQuery({
    queryKey: ["connectors", CONNECTORS[connectorType].name],
    queryFn: () => getUserConnectors(CONNECTORS[connectorType].name),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const navigate = useNavigate();
  const connectors = data?.data;

  if (!connectors) return null;

  return (
    <>
      <Box display="flex" width="full" margin={8} flexDir="column">
        <Box padding="8" bgColor={""}>
          <TopBar
            name={CONNECTORS[connectorType].name}
            ctaName="Add New"
            ctaIcon={<FiPlus color="gray.100" />}
            onCtaClicked={() => navigate("new")}
            isCtaVisible
          />
          {connectors ? (
            <ConnectorTable payload={connectors} />
          ) : (
            <NoConnectors connectorType={CONNECTORS[connectorType].name} />
          )}
        </Box>
      </Box>
    </>
  );
};

export default ViewAll;
