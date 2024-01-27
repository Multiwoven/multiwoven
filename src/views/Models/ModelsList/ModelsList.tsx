import TopBar from "@/components/TopBar";
import { getAllModels } from "@/services/models";
import { Box } from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { FiPlus } from "react-icons/fi";
import { Outlet, useNavigate } from "react-router-dom";

const ModelsList = (): JSX.Element | null => {
  const { data } = useQuery({
    queryKey: ["models"],
    queryFn: () => getAllModels(),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const models = data?.data;

  const navigate = useNavigate();

  if (!models) return null;

  return (
    <Box width="90%" mx="auto">
      <TopBar
        name={"Models"}
        ctaName="Add model"
        ctaIcon={<FiPlus color="gray.100" />}
        onCtaClicked={() => navigate("new")}
        isCtaVisible
      />
      <Outlet />
    </Box>
  );
};

export default ModelsList;
