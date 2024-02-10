import ContentContainer from "@/components/ContentContainer";
import TopBar from "@/components/TopBar";
import { Box } from "@chakra-ui/react";
import { FiPlus } from "react-icons/fi";
import { Outlet, useNavigate } from "react-router-dom";
import ModelTable from "./ModelTable";

const ModelsList = (): JSX.Element | null => {
  const navigate = useNavigate();

  const handleOnRowClick = (row: any) => {
    navigate(row?.id);
  };

  return (
    <Box width="100%" display="flex" flexDirection="column" alignItems="center">
      <ContentContainer>
        <TopBar
          name={"Models"}
          ctaName="Add Model"
          ctaIcon={<FiPlus color="gray.100" />}
          ctaButtonVariant="solid"
          onCtaClicked={() => navigate("new")}
          isCtaVisible
        />
        <Box mt={16}>
          <ModelTable handleOnRowClick={handleOnRowClick} />
        </Box>
        <Outlet />
      </ContentContainer>
    </Box>
  );
};

export default ModelsList;
