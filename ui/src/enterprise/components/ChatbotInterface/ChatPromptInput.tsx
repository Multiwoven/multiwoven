import React, { useRef, useEffect, useState, KeyboardEvent } from 'react';
import { Textarea, Box, HStack, Button, Icon, Flex, Text } from '@chakra-ui/react';
import { FiArrowUp, FiPaperclip, FiPlus, FiSend, FiX } from 'react-icons/fi';
import { useAssistantConfigStore } from '@/enterprise/store/useAssistantConfigStore';
import { FEATURE_FLAG_KEYS, useFeatureFlags } from '@/enterprise/hooks/useFeatureFlags';
import { FeatureFlagWrapper } from '@/components/FeatureFlagWrapper/FeatureFlagWrapper';
import ToolTip from '@/components/ToolTip';
import AssistantFileMessage from './AssistantFileMessage';
import { FlowComponent } from '@/enterprise/views/Agents/types';
import ContextComponentSelector, { SelectedAdditionalContexts } from './ContextComponentSelector';
import { ContextItemType } from '@/enterprise/store/useAppGenStore';
import FiAiWorkflows from '@/assets/icons/FiAiWorkflows';
import SessionFileAttach from './SessionFileAttach';
import AttachedFileChip from '@/enterprise/components/ChatbotComponents/AttachedFileChip';
import { WORKFLOW_FILE_ACCEPT } from '@/enterprise/services/workflowFileConstants';

export type ContextItem = {
  id: string;
  name: string;
  type: ContextItemType;
  icon?: string;
};

interface ChatPromptInputProps {
  value: string;
  file: File | null;
  isDisabled?: boolean;
  placeholder?: string;
  isWidget?: boolean;
  isAppGen?: boolean;
  contextPopup?: React.ReactNode;
  contextItems?: ContextItem[];
  borderColor?: string;
  onRemoveContextItem?: (id: string, type: ContextItemType) => void;
  onChange: (value: string) => void;
  onSend: () => void;
  handleAttachFile: () => void;
  contextComponents?: FlowComponent[];
  selectedContextComponents?: FlowComponent[];
  onToggleContextComponent?: (component: FlowComponent) => void;
  /** Session file upload (workflow file_input): separate from NASA attach. */
  isSessionFileUploadEnabled?: boolean;
  sessionAttachedFiles?: { file: File; isUploading: boolean }[];
  onSessionAttachFile?: (file: File) => void;
  onRemoveSessionFile?: (index: number) => void;
  /** When true, disable send (e.g. streaming or any file still uploading). */
  isSessionFilesUploading?: boolean;
}

const ChatPromptInput: React.FC<ChatPromptInputProps> = ({
  value,
  file,
  isDisabled = false,
  placeholder = 'Type your message...',
  isWidget,
  isAppGen,
  contextPopup,
  contextItems = [],
  borderColor = 'gray.500',
  onRemoveContextItem,
  onChange,
  onSend,
  handleAttachFile,
  contextComponents,
  selectedContextComponents = [],
  onToggleContextComponent,
  isSessionFileUploadEnabled = false,
  sessionAttachedFiles = [],
  onSessionAttachFile,
  onRemoveSessionFile,
  isSessionFilesUploading = false,
}) => {
  const features = useFeatureFlags([FEATURE_FLAG_KEYS.nasaFeatures]);
  const { setFile } = useAssistantConfigStore();
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const [height, setHeight] = useState('auto');
  const showSessionFileAttach =
    !features[FEATURE_FLAG_KEYS.nasaFeatures] &&
    isSessionFileUploadEnabled === true &&
    !!onSessionAttachFile;

  const blockSendWithoutMessageWithSessionFiles =
    showSessionFileAttach && sessionAttachedFiles.length > 0 && !value.trim();

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter') {
      // Shift+Enter or Cmd/Ctrl+Enter submits the message
      if (e.shiftKey || e.metaKey || e.ctrlKey) {
        e.preventDefault();
        if (!isDisabled && !isSessionFilesUploading && !blockSendWithoutMessageWithSessionFiles) {
          onSend();
        }
      }
      // Plain Enter adds a newline (default behavior, no action needed)
    }
  };

  useEffect(() => {
    const textarea = textareaRef.current;
    if (!textarea) return;
    textarea.style.height = 'auto'; // Reset height to recalc
    textarea.style.height = `${textarea.scrollHeight}px`;
    setHeight(`${textarea.scrollHeight}px`);
  }, [value]);

  return (
    <Box
      h='fit-content'
      w='100%'
      borderRadius='12px'
      borderWidth='1px'
      p='12px'
      gap='20px'
      display='flex'
      flexDir='column'
      bgColor='gray.100'
      borderColor={borderColor}
      opacity={isDisabled ? 0.5 : 1}
      cursor={isDisabled ? 'not-allowed' : 'text'}
    >
      {file && file.name && (
        <AssistantFileMessage
          filename={file.name}
          handleRemoveFile={() => setFile(null)}
          isViewOnly={false}
        />
      )}
      {isAppGen && contextItems.length > 0 && (
        <Flex gap='8px' flexWrap='wrap'>
          {contextItems.map((item) => (
            <Flex
              key={`${item.id}-${item.type}`}
              gap='4px'
              alignItems='center'
              px='8px'
              py='2px'
              borderRadius='4px'
              border='1px solid'
              borderColor='gray.500'
              bg='gray.200'
              flexShrink={0}
            >
              {item.icon ? (
                <Box as='img' src={item.icon} w='12px' h='12px' flexShrink={0} />
              ) : (
                <FiAiWorkflows viewBox='0 0 14 14' height='10px' width='10px' color='black.200' />
              )}
              <Text
                fontSize='12px'
                fontWeight={600}
                color='black.200'
                letterSpacing='-0.12px'
                lineHeight='18px'
                whiteSpace='nowrap'
              >
                {item.name}
              </Text>
              <Box
                as='button'
                onClick={() => onRemoveContextItem?.(item.id, item.type)}
                display='flex'
                alignItems='center'
                cursor='pointer'
                ml='2px'
                flexShrink={0}
              >
                <Icon as={FiX} w='10px' h='10px' color='gray.600' />
              </Box>
            </Flex>
          ))}
        </Flex>
      )}
      {selectedContextComponents.length > 0 && onToggleContextComponent && (
        <SelectedAdditionalContexts
          selectedContextComponents={selectedContextComponents}
          onToggleContextComponent={onToggleContextComponent}
        />
      )}
      {/* Session file_input chips; hidden when nasaFeatures (use NASA attach instead). */}
      {showSessionFileAttach && sessionAttachedFiles.length > 0 && (
        <Flex gap='8px' flexWrap='wrap' mb='8px'>
          {sessionAttachedFiles.map((sessionFile, index) => (
            <AttachedFileChip
              key={`${sessionFile.file.name}-${index}`}
              name={sessionFile.file.name}
              file={sessionFile.file}
              onRemove={() => onRemoveSessionFile?.(index)}
              showLoader={sessionFile.isUploading}
            />
          ))}
        </Flex>
      )}
      <Flex
        flexDir={isWidget ? 'row' : 'column'}
        alignItems={isWidget ? 'center' : 'normal'}
        {...(isAppGen && { gap: '20px' })}
      >
        <Textarea
          data-testid='chat-input'
          ref={textareaRef}
          height={height}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={placeholder}
          isDisabled={isDisabled}
          resize='none'
          overflow='auto'
          minHeight='40px'
          maxHeight={isAppGen ? '40px' : '200px'}
          p={0}
          fontSize='sm'
          border='none'
          focusBorderColor='gray.100'
          _placeholder={{
            color: 'gray.600',
          }}
          css={{
            '&::-webkit-scrollbar': {
              width: '2px',
            },
            '&::-webkit-scrollbar-thumb': {
              backgroundColor: 'var(--chakra-colors-gray-400)',
            },
          }}
        />
        <HStack flexDir={'row'} justifyContent={'space-between'}>
          <Flex gap='8px' alignItems='center'>
            {!isAppGen && (
              <>
                {/* NASA feature: attach file (feature-flag gated). */}
                <FeatureFlagWrapper flags={[FEATURE_FLAG_KEYS.nasaFeatures]}>
                  <ToolTip label={file ? 'Replace file' : 'Attach file'}>
                    <Button
                      variant='outline'
                      w='40px'
                      h='40px'
                      px='12px'
                      onClick={handleAttachFile}
                      isDisabled={isDisabled}
                    >
                      <Icon as={FiPaperclip} h='14px' w='14px' color='black.500' />
                    </Button>
                  </ToolTip>
                </FeatureFlagWrapper>
              </>
            )}
            {isAppGen && (
              <Box position='relative'>
                {contextPopup}
                <ToolTip label='Add context'>
                  <Button
                    variant='outline'
                    size='sm'
                    px='12px'
                    w='32px'
                    h='32px'
                    onClick={handleAttachFile}
                    isDisabled={isDisabled}
                  >
                    <Icon as={FiPlus} h='14px' w='14px' color='black.500' />
                  </Button>
                </ToolTip>
              </Box>
            )}
            {showSessionFileAttach && (
              <SessionFileAttach
                isEnabled
                accept={WORKFLOW_FILE_ACCEPT}
                onFileSelect={onSessionAttachFile}
                disabled={isDisabled}
              />
            )}
            {contextComponents && contextComponents.length > 0 && onToggleContextComponent && (
              <ContextComponentSelector
                contextComponents={contextComponents}
                selectedContextComponents={selectedContextComponents}
                onToggleContextComponent={onToggleContextComponent}
                isDisabled={isDisabled}
              />
            )}
          </Flex>
          <Button
            data-testid='chat-send-button'
            variant={isWidget ? 'transparent' : 'solid'}
            aria-label='Send message'
            isDisabled={
              isDisabled || isSessionFilesUploading || blockSendWithoutMessageWithSessionFiles
            }
            onClick={() => onSend()}
            w={isAppGen ? '32px' : '40px'}
            h={isAppGen ? '32px' : '40px'}
            px='12px'
            {...(isAppGen && { size: 'sm' })}
          >
            <Icon
              as={isWidget ? FiSend : FiArrowUp}
              h={isAppGen ? '14px' : '16px'}
              w={isAppGen ? '14px' : '16px'}
            />
          </Button>
        </HStack>
      </Flex>
    </Box>
  );
};

export default ChatPromptInput;
