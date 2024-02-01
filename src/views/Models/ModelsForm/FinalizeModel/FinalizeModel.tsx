import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import { extractDataByKey } from "@/utils";
import { ColumnMapType } from "@/utils/types";
import {
  Box,
  Flex,
  FormControl,
  FormLabel,
  Input,
  Select,
  Text,
  Textarea,
  VStack,
  useToast,
} from "@chakra-ui/react";
import { Formik, Form, Field, ErrorMessage } from "formik";
import { useContext, useState } from "react";
import * as Yup from "yup";
import ModelFooter from "../ModelFooter";
import { useQueryClient } from "@tanstack/react-query";

import { useNavigate } from "react-router-dom";
import { FinalizeForm } from "./types";
import { CreateModelPayload } from "../../types";
import { createNewModel } from "@/services/models";

type ModelConfig = {
  id: number;
  query: string;
  query_type: string;
  columns: ColumnMapType[];
};

type StepData = {
  step: number;
  data: { [key: string]: ModelConfig | any };
  stepKey: string;
};

const FinalizeModel = (): JSX.Element => {
  let defineModelData: StepData;

  const { state } = useContext(SteppedFormContext);
  defineModelData = extractDataByKey<StepData>(state.forms, "defineModel");

  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const toast = useToast();
  const [isLoading, setIsLoading] = useState(false);

  const validationSchema = Yup.object().shape({
    modelName: Yup.string().required("Model name is required"),
    description: Yup.string(),
    primaryKey: Yup.string().required("Primary Key is required"),
  });

  async function handleModelSubmit(values: FinalizeForm) {
    try {
      const payload: CreateModelPayload = {
        model: {
          connector_id: defineModelData?.data.defineModel.id,
          name: values.modelName,
          description: values.description,
          query: defineModelData?.data.defineModel.query,
          query_type: defineModelData?.data.defineModel.query_type,
          primary_key: values.primaryKey,
        },
      };

      setIsLoading(true);

      const createConnectorResponse = await createNewModel(payload);
      if (createConnectorResponse?.data) {
        queryClient.removeQueries({
          queryKey: ["Create Model"],
        });

        toast({
          status: "success",
          title: "Success!!",
          description: "Model created successfully!",
          position: "bottom-right",
        });
        navigate("/define/models");
      } else {
        throw new Error();
      }
    } catch {
      toast({
        status: "error",
        title: "An error occurred.",
        description: "Something went wrong while creating Model.",
        position: "bottom-right",
        isClosable: true,
      });
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <>
      <Box w="5xl" mx="auto" bgColor="gray.100" px={6} py={4}>
        <Text mb={6} fontWeight="bold">
          Finalize settings for this model
        </Text>
        <Formik
          initialValues={{
            modelName: "",
            description: "",
            primaryKey: "",
          }}
          validationSchema={validationSchema}
          onSubmit={(values) => {
            handleModelSubmit(values);
          }}
        >
          <Form>
            <VStack spacing={5}>
              <FormControl>
                <FormLabel
                  htmlFor="modelName"
                  fontSize="sm"
                  fontWeight="semibold"
                >
                  Model Name
                </FormLabel>
                <Field
                  as={Input}
                  id="modelName"
                  name="modelName"
                  placeholder="Enter a name"
                  bgColor="white"
                />
                <Text color="red.500" fontSize="sm">
                  <ErrorMessage name="modelName" />
                </Text>
              </FormControl>
              <FormControl>
                <FormLabel htmlFor="description" fontWeight="bold">
                  <Flex alignItems="center" fontSize="sm">
                    Description{" "}
                    <Text ml={2} fontSize="xs">
                      {" "}
                      (optional)
                    </Text>
                  </Flex>
                </FormLabel>
                <Field
                  as={Textarea}
                  id="description"
                  name="description"
                  placeholder="Enter a description"
                  bgColor="white"
                />
              </FormControl>
              <FormControl>
                <FormLabel htmlFor="primaryKey" fontSize="sm" fontWeight="bold">
                  Primary Key
                </FormLabel>
                <Field
                  as={Select}
                  placeholder="Select Primary Key"
                  name="primaryKey"
                  bgColor="white"
                  w="lg"
                >
                  {(defineModelData.data.defineModel.columns ?? []).map(
                    ({ key, name }: ColumnMapType, index: number) => (
                      <option key={index} value={key}>
                        {name}
                      </option>
                    )
                  )}
                </Field>
                <Text color="red.500" fontSize="sm">
                  <ErrorMessage name="primaryKey" />
                </Text>
              </FormControl>
            </VStack>
            <ModelFooter
              buttons={[
                {
                  name: "Back",
                  bgColor: "gray.300",
                  hoverBgColor: "gray.200",
                  color: "black",
                  onClick: () => navigate(-1),
                },
                {
                  name: "Finish",
                  bgColor: "primary.400",
                  hoverBgColor: "primary.300",
                  isLoading: isLoading,
                  type: "submit",
                },
              ]}
            />
          </Form>
        </Formik>
      </Box>
    </>
  );
};

export default FinalizeModel;
