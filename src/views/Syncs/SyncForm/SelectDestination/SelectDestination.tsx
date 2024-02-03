import ContentContainer from "@/components/ContentContainer";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import DestinationsTable from "@/views/Connectors/Destinations/DestinationsList/DestinationsTable";
import { Box } from "@chakra-ui/react";
import { useContext } from "react";

const SelectDestination = (): JSX.Element => {
  const { stepInfo, handleMoveForward } = useContext(SteppedFormContext);

  const handleOnRowClick = (data: unknown) => {
    handleMoveForward(stepInfo?.formKey as string, data);
  };

  return (
    <Box>
      <ContentContainer>
        <DestinationsTable
          handleOnRowClick={(data) => handleOnRowClick(data)}
        />
      </ContentContainer>
    </Box>
  );
};

export default SelectDestination;
