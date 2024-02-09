import { deleteModelById } from "@/services/models";
import {
  Box,
  Button,
  Flex,
  Image,
  Modal,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalOverlay,
  Text,
  useDisclosure,
  useToast,
} from "@chakra-ui/react";
import { FiTrash2 } from "react-icons/fi";
import { useNavigate, useParams } from "react-router-dom";
import ExitWarningImage from "@/assets/images/ExitWarning.png";

const DeleteModelModal = (): JSX.Element => {
  const { isOpen, onOpen, onClose } = useDisclosure();

  const params = useParams();
  const toast = useToast();
  const navigate = useNavigate();

  const model_id = params.id || "";

  async function handleDeleteModel() {
    try {
      await deleteModelById(model_id);
      toast({
        title: "Model deleted successfully",
        status: "success",
        isClosable: true,
        duration: 5000,
        position: "bottom-right",
      });
      navigate("/define/models");
    } catch (error) {
      toast({
        title: "Unable to delete model",
        description: "error",
        status: "error",
        isClosable: true,
        duration: 5000,
        position: "bottom-right",
      });
    }
  }

  return (
    <>
      <Button
        variant="solid"
        size="lg"
        onClick={onOpen}
        leftIcon={<FiTrash2 />}
      >
        Delete Model
      </Button>

      <Modal isOpen={isOpen} onClose={onClose} isCentered>
        <ModalOverlay bg="blackAlpha.400" />
        <ModalContent>
          <ModalCloseButton color="gray.300" />
          <ModalBody mx="auto" pt={10}>
            <Flex direction="column">
              <Image src={ExitWarningImage} h={32} w={48} mx="auto" my={8} />
              <Text fontWeight="bold" pt={8} fontSize={20} textAlign="center">
                Are you sure you want to delete this model?
              </Text>
              <Text fontWeight="light" fontSize={14} textAlign="center">
                This action will permanently delete the model and cannot be
                undone.
              </Text>
            </Flex>
          </ModalBody>

          <ModalFooter>
            <Box w="full">
              <Flex flexDir="row" justifyContent="center">
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
                <Button
                  variant="solid"
                  rounded="lg"
                  pr={10}
                  pl={10}
                  onClick={handleDeleteModel}
                >
                  Delete
                </Button>
              </Flex>
            </Box>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  );
};

export default DeleteModelModal;
