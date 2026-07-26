import DashedBox from '@/components/DashedBox';
import { CustomToastStatus } from '@/components/Toast';
import { uploadCustomComponent } from '@/enterprise/services/data-apps';
import { SchemaFieldOptions } from '@/enterprise/views/AIMLSources/types/types';
import useCustomToast from '@/hooks/useCustomToast';
import { useAPIErrorsToast, useErrorToast } from '@/hooks/useErrorToast';
import { Box, Text, Input, Button, Icon, Stack, Switch } from '@chakra-ui/react';
import { Dispatch, SetStateAction, ChangeEvent, useState, useEffect } from 'react';
import { FiCopy, FiFileText, FiKey, FiUpload, FiX } from 'react-icons/fi';

export type CustomVisualConfigProps = {
  fieldGroup?: string | null;
  fileId?: string | null;
  fileName?: string | null;
  sessionStorageKey?: string | null;
  modelFields: SchemaFieldOptions[];
  showVisual?: boolean | null;
  setFileId: Dispatch<SetStateAction<string | null | undefined>>;
  setFileName: Dispatch<SetStateAction<string | null | undefined>>;
  setSessionStorageKey: Dispatch<SetStateAction<string | null | undefined>>;
  handleFieldGroupSelect: Dispatch<SetStateAction<string | null | undefined>>;
  setShowVisual: Dispatch<SetStateAction<boolean | null | undefined>>;
};

const CustomVisualConfig = ({
  fileId,
  fileName,
  sessionStorageKey,
  showVisual,
  handleFieldGroupSelect,
  setFileId,
  setFileName,
  setSessionStorageKey,
  setShowVisual,
}: CustomVisualConfigProps) => {
  const [file, setFile] = useState<File | undefined>();
  const [isFileInServer, setIsFileInServer] = useState<boolean>(fileId ? true : false);
  const [isUploading, setIsUploading] = useState<boolean>(false);
  const [isUploadEnabled, setIsUploadEnabled] = useState<boolean>(file ? file.size > 0 : false);

  const toast = useCustomToast();
  const errorToast = useErrorToast();
  const apiErrorToast = useAPIErrorsToast();

  const handleUpload = async () => {
    if (file) {
      try {
        setIsUploading(true);
        if (file === undefined || file === null) {
          errorToast('No file selected', true, null, true);
          setIsUploading(false);
          return;
        }
        const data = await uploadCustomComponent(file);
        if (data.id) {
          setFileId(data.id.toString());
          handleFieldGroupSelect('custom'); // Will update code in V2 to support filtering values by group. We will be passing full response currently to the component.
          toast({
            title: 'Success!',
            description: 'Custom Script File Uploaded Successfully!',
            status: CustomToastStatus.Success,
            isClosable: true,
            position: 'bottom-right',
          });
        }
        if (data.errors) {
          apiErrorToast(data.errors);
        }
      } catch {
        errorToast('An Error Occurred, please try again.', true, null, true);
      } finally {
        setIsUploading(false);
      }
    }
  };

  async function setFileData(selectedFile: File) {
    try {
      const fileData = selectedFile;
      if (fileData.size === 0 || (await fileData.text()).length === 0) {
        errorToast('File is empty', true, null, true);
        return;
      }
      setFile(fileData);
      setIsUploadEnabled(true);
    } catch {
      setIsUploadEnabled(false);
      errorToast('An Error Occurred, please try again.', true, null, true);
    }
  }

  const handleFileChange = (event: ChangeEvent<HTMLInputElement>) => {
    const selectedFile = event.target.files?.[0];
    if (selectedFile === undefined) {
      errorToast('No file selected', true, null, true);
      setIsUploadEnabled(false);
      return;
    }
    if (selectedFile) {
      setFileData(selectedFile);
      setFileName(selectedFile.name);
    }
  };

  const handleCopyKey = () => {
    if (sessionStorageKey) {
      navigator.clipboard.writeText(sessionStorageKey);
      toast({
        title: 'Success!',
        description: 'Session Storage Key Copied Successfully!',
        status: CustomToastStatus.Success,
        isClosable: true,
        position: 'bottom-right',
      });
    } else {
      errorToast('No Session Storage Key Found', true, null, true);
    }
  };

  useEffect(() => {
    if (!sessionStorageKey) {
      const uuid = crypto.randomUUID();
      setSessionStorageKey(uuid);
      toast({
        title: 'Success!',
        description: 'Session Storage Key Generated Successfully!',
        status: CustomToastStatus.Success,
        isClosable: true,
        position: 'bottom-right',
      });
    }
  }, [sessionStorageKey]);

  return (
    <>
      <Box
        display='flex'
        flexDirection='column'
        gap='24px'
        data-testid='custom-visual-config-container'
      >
        <Box display='flex' justifyContent='space-between' alignItems='center'>
          <Text size='sm' fontWeight='semibold'>
            Show Visual
          </Text>
          <Switch
            onChange={(event) => setShowVisual(event.target.checked)}
            isChecked={showVisual ?? true}
          />
        </Box>
        <DashedBox backgroundColor='gray.200' hoverBackgroundColor='gray.200' padding='16px'>
          <Box display='flex' gap='8px' flexDir='column'>
            <Box display='flex' alignItems='center' gap='8px'>
              <Icon as={FiKey} color='black.300' />
              <Text color='black.500' fontWeight='semibold' size='sm'>
                Update Session Storage Key
              </Text>
            </Box>
            <Text color='black.100' fontWeight='regular' size='sm'>
              Update the session storage key to use a different key for the custom visual.
            </Text>
            <Box display='flex' gap='8px' flexDir={{ base: 'column', xl: 'row' }}>
              <Box
                display='flex'
                alignItems='center'
                gap='8px'
                justifyContent='space-between'
                backgroundColor='gray.200'
                borderColor='gray.500'
                borderWidth='1px'
                borderRadius='4px'
                px='8px'
                py='2px'
                overflowX='scroll'
              >
                <Text
                  data-testid='custom-visual-session-storage-key-value'
                  textColor='black.300'
                  size='xs'
                  fontWeight='semibold'
                  isTruncated
                >
                  {sessionStorageKey}
                </Text>
              </Box>
              <Button
                size='sm'
                variant='shell'
                minW='fit-content'
                w='fit-content'
                onClick={handleCopyKey}
              >
                <Box display='flex' alignItems='center' gap='4px'>
                  <Icon as={FiCopy} h='16px' w='16px' />
                  <Text size='xs' fontWeight='bold'>
                    Copy Key
                  </Text>
                </Box>
              </Button>
            </Box>
          </Box>
        </DashedBox>
        <Box display='flex' flexDirection='column' gap='8px'>
          <Text size='sm' fontWeight='semibold'>
            Custom Script
          </Text>
          <Box display='flex' flexDir='column'>
            {isFileInServer ? (
              <Box
                data-testid='custom-visual-script-on-server'
                display='flex'
                justifyContent='space-between'
                alignItems='center'
                w='100%'
                h='fit-content'
                p='16px'
                bgColor='gray.200'
                border='1px'
                borderRadius='6px'
                borderColor='gray.400'
              >
                <Box display='flex' gap='8px' alignItems='center'>
                  <Icon as={FiFileText} />
                  <Text fontSize='sm' fontWeight='semibold'>
                    {fileName || 'custom_script.js'}
                  </Text>
                </Box>
                <Box
                  as='button'
                  type='button'
                  onClick={() => setIsFileInServer(false)}
                  cursor='pointer'
                  data-testid='custom-visual-remove-uploaded-file'
                  aria-label='Remove uploaded file'
                  display='flex'
                  alignItems='center'
                  justifyContent='center'
                  background='transparent'
                  border='none'
                  p={0}
                >
                  <Icon as={FiX} />
                </Box>
              </Box>
            ) : (
              <Stack gap='4px'>
                <Box display='flex' gap={2} flexDirection={{ base: 'column', xl: 'row' }}>
                  <Input
                    type='file'
                    onChange={handleFileChange}
                    data-testid='custom-visual-file-input'
                    size='md'
                    placeholder='asdf'
                    fontSize='sm'
                    fontWeight='medium'
                    color='black.100'
                    accept='.js'
                    p={1}
                  />
                  <Button
                    onClick={() => handleUpload()}
                    leftIcon={<FiUpload color='black.100' />}
                    data-testid='custom-visual-file-upload-btn'
                    isDisabled={!isUploadEnabled}
                    isLoading={isUploading}
                  >
                    Upload
                  </Button>
                </Box>
                <Text size='xs' textColor='gray.600' fontWeight='medium'>
                  Only .js build files are supported (Max 2MB)
                </Text>
              </Stack>
            )}
          </Box>
        </Box>
      </Box>
    </>
  );
};

export default CustomVisualConfig;
