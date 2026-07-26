import {
  IconButton,
  Input,
  InputGroup,
  InputProps,
  InputRightElement,
  useDisclosure,
} from '@chakra-ui/react';
import { FiEye, FiEyeOff } from 'react-icons/fi';

<<<<<<< HEAD
const HiddenInput = (props: InputProps): JSX.Element => {
=======
const HiddenInput = (
  props: InputProps & { label?: string; isRequired?: boolean; 'data-testid'?: string },
): JSX.Element => {
>>>>>>> e6895d051 (chore(CE): Add data-testid for Knowledge Base E2E Testing (#1891))
  const { isOpen, onToggle } = useDisclosure();

  const onClickReveal = () => {
    onToggle();
  };

<<<<<<< HEAD
  return (
    <InputGroup>
      <Input
        id={props.id}
        name='password'
        autoComplete='current-password'
        required
        {...props}
        type={isOpen ? 'text' : 'password'}
      />
      <InputRightElement>
        <IconButton
          variant='text'
          aria-label={isOpen ? 'Mask password' : 'Reveal password'}
          icon={isOpen ? <FiEyeOff /> : <FiEye />}
          onClick={onClickReveal}
        />
      </InputRightElement>
    </InputGroup>
=======
  const { label, isRequired, 'data-testid': dataTestId, ...rest } = props;

  return (
    <Box width='100%' display='flex' flexDirection='column' gap='8px'>
      <Box display='flex' flexDirection='row' gap='1px' alignItems='center'>
        <Text fontWeight='semibold' size='sm'>
          {label}
        </Text>
        {isRequired && (
          <Text size='sm' color='error.400'>
            *
          </Text>
        )}
      </Box>
      <InputGroup>
        <Input
          id={rest.id}
          name='password'
          autoComplete='current-password'
          {...rest}
          type={isOpen ? 'text' : 'password'}
          data-testid={dataTestId ?? 'hidden-input-field'}
        />
        <InputRightElement>
          <IconButton
            variant='text'
            color='gray.600'
            aria-label={isOpen ? 'Mask password' : 'Reveal password'}
            icon={isOpen ? <FiEyeOff /> : <FiEye />}
            onClick={onClickReveal}
            isDisabled={rest.isDisabled}
            disabled={rest.isDisabled}
          />
        </InputRightElement>
      </InputGroup>
    </Box>
>>>>>>> e6895d051 (chore(CE): Add data-testid for Knowledge Base E2E Testing (#1891))
  );
};

export default HiddenInput;
