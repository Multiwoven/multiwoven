import {
  Box,
  Breadcrumb,
  BreadcrumbItem,
  Button,
  Flex,
  FormControl,
  FormHelperText,
  FormLabel,
  Input,
  Switch,
  Text,
} from '@chakra-ui/react';
import { useMemo, useState } from 'react';

type CreateFolderViewProps = {
  /** Already-created folder names — used for client-side uniqueness check. */
  existingFolderNames: string[];
  onSubmit: (params: { name: string; isPublic: boolean }) => void | Promise<void>;
  onCancel: () => void;
  /** External in-flight flag — disables footer buttons while save is running. */
  isSubmitting?: boolean;
};

const NAME_REGEX = /^[a-z0-9-]+$/;
const MIN_LEN = 3;
const MAX_LEN = 63;

function validateFolderName(name: string, existing: string[]): string | null {
  if (name.length === 0) return null; // don't show errors until user types
  if (name.length < MIN_LEN) return `Must be at least ${MIN_LEN} characters.`;
  if (name.length > MAX_LEN) return `Must be at most ${MAX_LEN} characters.`;
  if (!NAME_REGEX.test(name)) return 'Lowercase letters, numbers, and hyphens only.';
  if (existing.includes(name)) return 'A folder with this name already exists.';
  return null;
}

export function CreateFolderView({
  existingFolderNames,
  onSubmit,
  onCancel,
  isSubmitting = false,
}: CreateFolderViewProps): JSX.Element {
  const [name, setName] = useState('');
  const [isPublic, setIsPublic] = useState(false);
  const [touched, setTouched] = useState(false);

  const validationError = useMemo(
    () => validateFolderName(name, existingFolderNames),
    [name, existingFolderNames],
  );
  const canSubmit = name.length >= MIN_LEN && validationError === null && !isSubmitting;

  const handleSubmit = async (): Promise<void> => {
    setTouched(true);
    if (!canSubmit) return;
    await onSubmit({ name, isPublic });
  };

  return (
    <Flex direction='column' w='100%' h='100%' minH={0}>
      {/* Header: breadcrumb + page title */}
      <Flex
        direction='column'
        gap='2px'
        px='24px'
        pt='16px'
        pb='16px'
        borderBottomWidth='1px'
        borderColor='gray.400'
      >
        <Breadcrumb separator='/' color='gray.600' fontSize='sm'>
          <BreadcrumbItem>
            <Text
              as='button'
              fontSize='sm'
              color='black.100'
              fontWeight='regular'
              onClick={onCancel}
              _hover={{ color: 'black.500' }}
            >
              Storage
            </Text>
          </BreadcrumbItem>
          <BreadcrumbItem isCurrentPage>
            <Text fontSize='sm' color='black.500' fontWeight='semibold' noOfLines={1}>
              Add new folder
            </Text>
          </BreadcrumbItem>
        </Breadcrumb>
        <Text fontSize='lg' fontWeight='semibold' color='black.500'>
          Add new folder
        </Text>
      </Flex>

      {/* Form body */}
      <Box flex='1' minH={0} overflowY='auto' px='24px' py='24px'>
        <Flex direction='column' gap='24px' maxW='504px'>
          <FormControl isInvalid={touched && !!validationError}>
            <FormLabel fontSize='sm' fontWeight='semibold' color='black.500' mb='6px'>
              Folder Name
            </FormLabel>
            <Input
              size='md'
              placeholder='Enter a folder name'
              value={name}
              onChange={(e) => setName(e.target.value)}
              onBlur={() => setTouched(true)}
              maxLength={MAX_LEN}
              isDisabled={isSubmitting}
              data-testid='app-builder-folder-name'
            />
            {touched && validationError ? (
              <FormHelperText color='error.500' mt='6px'>
                {validationError}
              </FormHelperText>
            ) : (
              <FormHelperText color='black.100' mt='6px'>
                Lowercase letters, numbers, and hyphens only. Must be {MIN_LEN}-{MAX_LEN}{' '}
                characters. Folder names must be unique and cannot be changed after creation.
              </FormHelperText>
            )}
          </FormControl>

          <Flex align='center' justify='space-between' gap='16px'>
            <Flex direction='column' gap='4px' minW={0} flex='1'>
              <Text fontSize='sm' fontWeight='semibold' color='black.500'>
                Make Folder Public
              </Text>
              <Text fontSize='xs' color='black.100'>
                Files in private folder require authentication to access.
              </Text>
            </Flex>
            <Switch
              isChecked={isPublic}
              onChange={(e) => setIsPublic(e.target.checked)}
              colorScheme='brand'
              isDisabled={isSubmitting}
              data-testid='app-builder-make-folder-public'
            />
          </Flex>
        </Flex>
      </Box>

      {/* Footer */}
      <Flex
        align='center'
        justify='flex-end'
        gap='12px'
        px='24px'
        py='20px'
        borderTopWidth='1px'
        borderColor='gray.400'
      >
        <Button
          variant='shell'
          size='md'
          minWidth={0}
          width='auto'
          onClick={onCancel}
          isDisabled={isSubmitting}
        >
          Cancel
        </Button>
        <Button
          variant='solid'
          size='md'
          minWidth={0}
          width='auto'
          onClick={handleSubmit}
          isLoading={isSubmitting}
          isDisabled={!canSubmit}
          data-testid='app-builder-create-folder'
        >
          Create Folder
        </Button>
      </Flex>
    </Flex>
  );
}
