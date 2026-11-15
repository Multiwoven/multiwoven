import OptionCard from '@/enterprise/components/OptionCard';
import {
  Box,
  Button,
  Drawer,
  DrawerBody,
  DrawerCloseButton,
  DrawerContent,
  DrawerFooter,
  DrawerHeader,
  DrawerOverlay,
  RadioGroup,
  Text,
} from '@chakra-ui/react';
import { useState, useEffect } from 'react';
import { FiDatabase, FiLayers } from 'react-icons/fi';
import CreateVectorStoreKBForm from './CreateVectorStoreKBForm';
import useKnowledgeBaseMutations from '@/enterprise/hooks/mutations/useKnowledgeBaseMutations';
import { CreateKnowledgeBasePayload } from '@/enterprise/services/knowledge-base';
import { useAPIErrorsToast } from '@/hooks/useErrorToast';

type KBStep = {
  title: string;
  description?: string;
  content: JSX.Element;
  footer: JSX.Element;
};

type CreateAndViewKBDrawerProps = {
  isOpen: boolean;
  onClose: () => void;
  viewOnly: boolean;
  defaultPayload?: CreateKnowledgeBasePayload;
  refetchKnowledgeBases?: () => void;
};

const CreateAndViewKBDrawer = ({
  isOpen,
  onClose,
  viewOnly,
  defaultPayload,
  refetchKnowledgeBases,
}: CreateAndViewKBDrawerProps) => {
  const getDefaultPayload = (): CreateKnowledgeBasePayload => {
    return (
      defaultPayload || {
        name: '',
        knowledge_base_type: 'vector_store',
        embedding_config: {
          embedding_provider: '',
          embedding_model: '',
          api_key: '',
          chunk_size: 1000,
          chunk_overlap: 250,
        },
        storage_config: {
          table_name: '',
          text_column_name: null,
          vector_column_name: null,
          metadata_column_name: null,
        },
        hosted_data_store_id: null,
        source_connector_id: null,
        destination_connector_id: null,
      }
    );
  };

  const [currentStep, setCurrentStep] = useState(0);
  const [createPayload, setCreatePayload] = useState<CreateKnowledgeBasePayload>(() =>
    getDefaultPayload(),
  );

  // Sync createPayload when defaultPayload prop changes
  useEffect(() => {
    setCreatePayload(getDefaultPayload());
  }, [defaultPayload]);

  const { createKnowledgeBase } = useKnowledgeBaseMutations();
  const apiErrorToast = useAPIErrorsToast();

  const handleCreateKnowledgeBase = (data: CreateKnowledgeBasePayload) => {
    createKnowledgeBase.mutate(data, {
      onSuccess: (data) => {
        if (data.data?.id) {
          onClose();
          setCurrentStep(0);
          refetchKnowledgeBases?.();
          createKnowledgeBase.reset();
          setCreatePayload(getDefaultPayload());
        }

        if (data.errors) {
          apiErrorToast(data.errors);
        }
      },
    });
  };

  const preventCreateKnowledgeBase =
    !createPayload.name ||
    !createPayload.embedding_config.embedding_provider ||
    !createPayload.embedding_config.embedding_model ||
    !createPayload.embedding_config.api_key ||
    !createPayload.storage_config.table_name ||
    !createPayload.storage_config.text_column_name ||
    !createPayload.storage_config.vector_column_name ||
    !createPayload.storage_config.metadata_column_name ||
    !createPayload.hosted_data_store_id;

  const CREATE_KB_STEPS: KBStep[] = [
    ...(!viewOnly
      ? [
          {
            title: 'Create new knowledge base',
            content: (
              <RadioGroup
                value={createPayload.knowledge_base_type}
                onChange={(value) =>
                  setCreatePayload({
                    ...createPayload,
                    knowledge_base_type: value as 'vector_store',
                  })
                }
              >
                <Box display='flex' flexDirection='row' gap='16px'>
                  <OptionCard
                    optionText='Vector Store'
                    optionDesc='Import from files, data connectors and websites.'
                    optionIcon={FiLayers}
                    optionValue='vector_store'
                    testId='vector-store-option'
                  />
                  <OptionCard
                    optionText='Semantic Data Model'
                    optionDesc='Structured data from databases or CSV files.'
                    optionIcon={FiDatabase}
                    optionValue='semantic_data_model'
                    isComingSoon
                    isDisabled
                    testId='semantic-data-model-option'
                  />
                </Box>
              </RadioGroup>
            ),
            footer: (
              <Box display='flex' gap='12px' alignItems='center' width='100%' justifyContent='end'>
                <Button
                  width='fit-content'
                  variant='ghost'
                  onClick={() => {
                    onClose();
                    setCurrentStep(0);
                    createKnowledgeBase.reset();
                    setCreatePayload(getDefaultPayload());
                  }}
                >
                  Cancel
                </Button>
                <Button
                  data-testid='create-kb-continue-button'
                  width='fit-content'
                  onClick={() => setCurrentStep(currentStep + 1)}
                >
                  Continue
                </Button>
              </Box>
            ),
          },
        ]
      : []),
    {
      title: viewOnly ? 'Configurations' : 'Create new vector store',
      content: (
        <CreateVectorStoreKBForm
          createPayload={createPayload}
          setCreatePayload={setCreatePayload}
          readonly={viewOnly}
        />
      ),
      footer: (
        <Box display='flex' gap='12px' alignItems='center' width='100%' justifyContent='end'>
          <Button
            width='fit-content'
            variant='ghost'
            onClick={() => {
              onClose();
              setCurrentStep(0);
              setCreatePayload(getDefaultPayload());
            }}
          >
            Cancel
          </Button>
          <Button
            data-testid='create-kb-submit-button'
            width='fit-content'
            onClick={() => {
              handleCreateKnowledgeBase(createPayload);
            }}
            isDisabled={viewOnly ? true : preventCreateKnowledgeBase}
            isLoading={createKnowledgeBase.isPending}
            loadingText='Creating'
          >
            {viewOnly ? 'Save Changes' : 'Continue'}
          </Button>
        </Box>
      ),
    },
  ];

  return (
    <>
      <Drawer placement='right' onClose={onClose} isOpen={isOpen} size='lg'>
        <DrawerOverlay />
        <DrawerContent width='600px' maxHeight='100vh'>
          <DrawerCloseButton color='gray.600' />
          <DrawerHeader>
            <Text size='xl' fontWeight='bold' color='black.500'>
              {CREATE_KB_STEPS[currentStep].title}
            </Text>
          </DrawerHeader>
          <DrawerBody display='flex' flexDirection='column' gap='24px'>
            <Box width='100%'>{CREATE_KB_STEPS[currentStep].content}</Box>
          </DrawerBody>
          <DrawerFooter
            gap='12px'
            borderTopWidth='1px'
            borderTopColor='gray.200'
            mt='auto'
            justifyContent='end'
          >
            {CREATE_KB_STEPS[currentStep].footer}
          </DrawerFooter>
        </DrawerContent>
      </Drawer>
    </>
  );
};

export default CreateAndViewKBDrawer;
