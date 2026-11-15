import ActionBadge from '@/components/ActionBadge/ActionBadge';
import BaseModal from '@/components/BaseModal';
import TextareaHighlighter from '@/components/TextareaHighlighter';
import ToolTip from '@/components/ToolTip';
import { Text, Flex, Box, Button, useDisclosure, Divider } from '@chakra-ui/react';
import { WidgetProps } from '@rjsf/utils';
import { useEffect, useState } from 'react';
import { FiAlignLeft, FiInfo, FiPlus } from 'react-icons/fi';

const PromptInput = ({ value, required, onChange, label, options }: WidgetProps) => {
  const { isOpen, onClose, onOpen } = useDisclosure();
  const [prompt, setPrompt] = useState(value ?? '');

  useEffect(() => {
    setPrompt(value);
  }, [value]);

  return (
    <Box key={value ?? 'new-prompt-input'}>
      <Flex gap='10px' flexDir='column'>
        <Flex gap='8px' alignItems={'center'}>
          <Flex gap='4px'>
            <Text size={'sm'} fontWeight={600}>
              {label}
            </Text>
            {required && <Box color='error.400'>*</Box>}
          </Flex>
          {options?.tooltip && (
            <ToolTip label={options.tooltip as string}>
              <Box color='gray.600'>
                <FiInfo width='14px' height='14px' />
              </Box>
            </ToolTip>
          )}
        </Flex>
        <Box
          border='1px solid'
          borderColor='gray.400'
          borderRadius='6px'
          data-testid='workflow-prompt-template-editor-open'
          onClick={() => onOpen()}
        >
          <TextareaHighlighter
            padding='12px'
            height='116px'
            placeholder='Type your prompt here'
            value={value}
            onChange={(e) => setPrompt(e.target.value)}
          />
        </Box>
      </Flex>
      <BaseModal
        title='Edit Prompt'
        footer={
          <Box display='flex' gap='12px'>
            <Button
              variant='ghost'
              w='fit-content'
              onClick={() => {
                onClose();
              }}
            >
              Cancel
            </Button>
            <Button
              data-testid='save-changes-button'
              onClick={() => {
                onChange(prompt);
                onClose();
              }}
            >
              Save Prompt
            </Button>
          </Box>
        }
        openModal={isOpen}
        setModalOpen={onClose}
      >
        <Flex gap='24px' flexDir='column'>
          <Flex gap='12px' flexDir='column'>
            <Text size='sm' fontWeight={600}>
              Prompt Templates
            </Text>
            <Flex gap='12px'>
              <ActionBadge
                icon={<FiAlignLeft size='14px' />}
                actionIcon={<FiPlus size={'14px'} />}
                description='Text-to-SQL'
                tooltipText=''
                action={() =>
                  setPrompt(
                    `You are given a database schema and a user question. Based on the schema, write a valid SQL query that answers the question.\nSchema: {db_schmea}\n\nQuestion: {user_input}\n\nOutput:\n Provide only the SQL query without any explanation.`,
                  )
                }
              />
            </Flex>
          </Flex>
          <Flex gap='4px' flexDir='column'>
            <Flex gap='8px' alignItems={'center'}>
              <Flex gap='4px'>
                <Text size={'sm'} fontWeight={600}>
                  Prompt
                </Text>
                {required && <Box color='error.400'>*</Box>}
              </Flex>
              {options?.tooltip && (
                <ToolTip label={options.tooltip as string}>
                  <Box color='gray.600'>
                    <FiInfo width='14px' height='14px' />
                  </Box>
                </ToolTip>
              )}
            </Flex>
            <Flex
              flexDir='column'
              gap='12px'
              padding='12px'
              border='1px solid'
              borderColor='gray.400'
              borderRadius='6px'
              data-testid='workflow-prompt-template-editor'
            >
              <TextareaHighlighter
                placeholder='Type your prompt here'
                value={prompt}
                defaultValue={value}
                onChange={(e) => setPrompt(e.target.value)}
              />
              <Divider orientation='horizontal' borderColor='gray.400' />
              <Flex flexDir='column' gap='8px'>
                <Text size='sm' color='black.100'>
                  {
                    'Insert dynamic variables to the prompt using curly braces, e.g., {variable_name}'
                  }
                </Text>
              </Flex>
            </Flex>
          </Flex>
        </Flex>
      </BaseModal>
    </Box>
  );
};

export default PromptInput;
