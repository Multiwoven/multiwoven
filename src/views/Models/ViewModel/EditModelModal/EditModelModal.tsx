import { putModelById } from "@/services/models";
import {
  Box,
  Button,
  Flex,
  FormControl,
  FormLabel,
  Modal,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalHeader,
  ModalOverlay,
  Text,
  VStack,
  useDisclosure,
  useToast,
  Input,
  Textarea,
} from "@chakra-ui/react";
import { FiEdit3 } from "react-icons/fi";
import { useParams } from "react-router-dom";
import { ErrorMessage, Field, Form, Formik } from "formik";
import * as Yup from "yup";
import { PrefillValue } from "../../ModelsForm/DefineModel/DefineSQL/types";
import { ModelSubmitFormValues, UpdateModelPayload } from "../types";
import { useState } from "react";

const EditModelModal = (prefillValues: PrefillValue): JSX.Element => {
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [loading, setLoading] = useState(false);

  const params = useParams();
  const toast = useToast();

  const model_id = params.id || "";

  async function handleModelUpdate(values: ModelSubmitFormValues) {
    const updatePayload: UpdateModelPayload = {
      model: {
        name: values.modelName,
        description: values.description,
        primary_key: prefillValues.primary_key,
        connector_id: prefillValues.connector_id || "",
        query: prefillValues.query,
        query_type: prefillValues.query_type,
      },
    };

    const modelUpdateResponse = await putModelById(model_id, updatePayload);
    if (modelUpdateResponse.data) {
      toast({
        title: "Model updated successfully",
        status: "success",
        duration: 3000,
        isClosable: true,
        position: "bottom-right",
      });
      setLoading(false);
      onClose();
    }
    setLoading(false);
  }

  const validationSchema = Yup.object().shape({
    modelName: Yup.string().required("Model name is required"),
    description: Yup.string(),
  });

  return (
    <>
      <Button
        variant="outline"
        size="lg"
        onClick={onOpen}
        leftIcon={<FiEdit3 />}
      >
        Edit Details
      </Button>

      <Modal isOpen={isOpen} onClose={onClose} isCentered size="2xl">
        <ModalOverlay bg="blackAlpha.400" />
        <ModalContent>
          <ModalCloseButton color="gray.300" />
          <ModalHeader>
            <Text>Edit Details</Text>
            <Text fontSize="md" color="gray.700" fontWeight="light">
              Edit the settings for this model
            </Text>
          </ModalHeader>
          <ModalBody>
            <Formik
              initialValues={{
                modelName: prefillValues.model_name,
                description: prefillValues.model_description,
              }}
              validationSchema={validationSchema}
              onSubmit={(values) => {
                handleModelUpdate(values);
                setLoading(true);
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
                      variant="outline"
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
                </VStack>
                <Box w="full" pt={8}>
                  <Flex flexDir="row" justifyContent="end">
                    <Button
                      bgColor="gray.300"
                      variant="ghost"
                      color="black"
                      mr={3}
                      onClick={onClose}
                      size="md"
                      pr={8}
                      pl={8}
                      rounded="lg"
                    >
                      Cancel
                    </Button>
                    <Button type="submit" isLoading={loading}>
                      Save Changes
                    </Button>
                  </Flex>
                </Box>
              </Form>
            </Formik>
          </ModalBody>
        </ModalContent>
      </Modal>
    </>
  );
};

export default EditModelModal;
