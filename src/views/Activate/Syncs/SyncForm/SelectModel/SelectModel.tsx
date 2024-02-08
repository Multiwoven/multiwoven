import ContentContainer from "@/components/ContentContainer";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import ModelTable from "@/views/Models/ModelsList/ModelTable";
import { Box } from "@chakra-ui/react";
import { useContext } from "react";

const SelectModel = (): JSX.Element => {
  const { stepInfo, handleMoveForward } = useContext(SteppedFormContext);

  const handleOnRowClick = (data: unknown) => {
    handleMoveForward(stepInfo?.formKey as string, data);
  };

  return (
    <Box width="100%" display="flex" justifyContent="center">
      <ContentContainer>
        <ModelTable handleOnRowClick={handleOnRowClick} />
      </ContentContainer>
    </Box>
  );
};

export default SelectModel;
