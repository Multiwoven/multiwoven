import ContentContainer from "@/components/ContentContainer";
import TopBar from "@/components/TopBar";
import { fetchSyncs } from "@/services/syncs";
import { Box, Spinner } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { FiPlus } from "react-icons/fi";
import { useNavigate } from "react-router-dom";

const SyncsList = (): JSX.Element => {
  const navigate = useNavigate();
  const { data, isLoading } = useQuery({
    queryKey: ["activate", "syncs"],
    queryFn: () => fetchSyncs(),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const syncList = data?.data;
  console.log(syncList);
  

  if (!syncList || isLoading) {
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

  return (
    <Box width="100%" display="flex" flexDirection="column" alignItems="center">
      <ContentContainer>
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
      </ContentContainer>
    </Box>
  );
};

export default SyncsList;
