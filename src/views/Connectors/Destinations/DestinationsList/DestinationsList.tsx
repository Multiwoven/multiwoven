import { Box } from "@chakra-ui/react";
import { FiPlus } from "react-icons/fi";
import TopBar from "@/components/TopBar";
import { useNavigate } from "react-router-dom";

import ContentContainer from "@/components/ContentContainer";
import DestinationsTable from "./DestinationsTable";

const DestinationsList = (): JSX.Element | null => {
  const navigate = useNavigate();

  return (
    <Box width="100%" display="flex" flexDirection="column" alignItems="center">
      <ContentContainer>
        <TopBar
          name="Destinations"
          ctaName="Add Destination"
          ctaIcon={<FiPlus color="gray.100" />}
          onCtaClicked={() => navigate("new")}
          ctaButtonVariant="solid"
          ctaButtonWidth="fit"
          ctaButtonHeight="40px"
          isCtaVisible
        />
        <DestinationsTable
          handleOnRowClick={(row) => navigate(`/setup/destinations/${row?.id}`)}
        />
      </ContentContainer>
    </Box>
  );
};

export default DestinationsList;
