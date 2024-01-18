import { useContext, useEffect } from "react";
import { Box, Image, Text } from "@chakra-ui/react";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { getConnectorsDefintions } from "@/services/connectors";
import { useQuery } from "@tanstack/react-query";
import { DatasourceType } from "@/views/Connectors/types";

const SelectDataSourcesForm = (): JSX.Element => {
  const { state, dispatch, stepInfo } = useContext(SteppedFormContext);
  const { currentForm } = state;
  const { data } = useQuery({
    queryKey: ["datasources", "source"],
    queryFn: () => getConnectorsDefintions("source"),
    refetchOnWindowFocus: false,
    refetchOnMount: false,
    gcTime: Infinity,
  });

  useEffect(() => {
    getConnectorsDefintions("source");
  }, []);

  const datasources = data?.data ?? [];

  const handleOnClick = (datasource: DatasourceType) => {
    if (stepInfo?.formKey) {
      dispatch({
        type: "UPDATE_CURRENT_FORM",
        payload: {
          stepKey: stepInfo?.formKey,
          data: datasource.name,
        },
      });
    }
  };

  return (
    <Box display="flex" flexDirection="column" alignItems="center">
      <Box
        display="grid"
        gridTemplateColumns="1fr 1fr"
        gap="20px"
        marginBottom="20px"
        paddingY="20px"
        paddingX="30px"
        maxWidth="1300px"
        width="100%"
      >
        {datasources.map((datasource) => (
          <Box
            key={datasource.name}
            padding="20px"
            width="100%"
            borderRadius="8px"
            borderWidth="thin"
            marginRight="10px"
            marginBottom="10px"
            cursor="pointer"
            display="flex"
            alignItems="center"
            onClick={() => handleOnClick(datasource)}
            backgroundColor={
              currentForm?.datasource === datasource.name ? "gray.100" : "white"
            }
          >
            <Box>
              <Image
                src={"/src/assets/icons/" + datasource.icon}
                height="8"
                w="min"
                mr={3}
              />
            </Box>
            <Box>
              <Text fontWeight={600}>{datasource.name}</Text>
            </Box>
          </Box>
        ))}
      </Box>
    </Box>
  );
};

export default SelectDataSourcesForm;
