import TopBar from "@/components/TopBar";
import { Box } from "@chakra-ui/react";
import { FiPlus } from "react-icons/fi";
import { useNavigate } from "react-router-dom";

const SyncsList = (): JSX.Element => {
  const navigate = useNavigate();

  return (
    <Box>
      <TopBar
        name="Syncs"
        ctaName="Add sync"
        ctaIcon={<FiPlus color="gray.100" />}
        onCtaClicked={() => navigate("new")}
        ctaBgColor="orange.500"
        ctaColor="gray.900"
        ctaHoverBgColor="orange.400"
        isCtaVisible
      />
    </Box>
  );
};

export default SyncsList;
