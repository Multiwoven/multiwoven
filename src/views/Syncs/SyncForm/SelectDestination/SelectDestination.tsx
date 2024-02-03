import ContentContainer from "@/components/ContentContainer";
import DestinationsTable from "@/views/Connectors/Destinations/DestinationsList/DestinationsTable";
import { Box } from "@chakra-ui/react";

const SelectDestination = (): JSX.Element => {
  return (
    <Box>
      <ContentContainer>
        <DestinationsTable
          handleOnRowClick={(data) => console.log("Clicked: ", data)}
        />
      </ContentContainer>
    </Box>
  );
};

export default SelectDestination;
