import {
  Box,
  Card,
  CardBody,
  Heading,
  Image,
  SimpleGrid,
  Stack,
  Text,
} from "@chakra-ui/react";
import { modelMethods } from "./methods";
import { useContext } from "react";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { ModelMethodType } from "./types";
import ModelFooter from "../ModelFooter";
import { useNavigate } from "react-router-dom";
import ContentContainer from "@/components/ContentContainer";

const ModelMethod = (): JSX.Element => {
  const { stepInfo, handleMoveForward } = useContext(SteppedFormContext);

  const handleOnClick = (method: ModelMethodType) => {
    if (stepInfo?.formKey) {
      handleMoveForward(stepInfo.formKey, method.name);
    }
  };

  const navigate = useNavigate();
  return (
    <Box width="100%" display="flex" justifyContent="center">
      <ContentContainer>
        <SimpleGrid columns={3} spacing={8}>
          {modelMethods.map((method, index) => (
            <Card
              maxW="sm"
              key={index}
              _hover={method.enabled ? { bgColor: "gray.50" } : {}}
              variant={!method.enabled ? "elevated" : "elevated"}
              onClick={method.enabled ? () => handleOnClick(method) : () => {}}
            >
              <CardBody>
                <Image
                  src={method.image}
                  alt={method.type}
                  borderRadius="lg"
                  w="full"
                />
                <Stack mt="6" spacing="3">
                  <Text textAlign="center">weaving soon</Text>
                  <Heading size="md">{method.name}</Heading>
                  <Text>{method.description}</Text>
                </Stack>
              </CardBody>
            </Card>
          ))}
        </SimpleGrid>
        <ModelFooter
          buttons={[
            {
              name: "Back",
              bgColor: "gray.300",
              hoverBgColor: "gray.200",
              color: "black",
              onClick: () => navigate(-1),
            },
          ]}
        />
      </ContentContainer>
    </Box>
  );
};

export default ModelMethod;
