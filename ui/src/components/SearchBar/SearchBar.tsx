import { Input, InputGroup, InputLeftElement, Icon } from '@chakra-ui/react';
import { FiSearch } from 'react-icons/fi';
import { Dispatch, SetStateAction } from 'react';

type SearchBarProps = {
  setSearchTerm: Dispatch<SetStateAction<string>>;
  placeholder: string;
  borderColor: string;
<<<<<<< HEAD
};

const SearchBar = ({ setSearchTerm, placeholder, borderColor }: SearchBarProps) => (
  <InputGroup>
=======
  width?: string;
  'data-testid'?: string;
};

const SearchBar = ({
  setSearchTerm,
  placeholder,
  borderColor,
  width = '100%',
  'data-testid': dataTestId,
}: SearchBarProps) => (
  <InputGroup w={width} h='40px'>
>>>>>>> deba42b89 (feat(CE): data-testid hooks for models, Data Apps, and workflows (#1835))
    <InputLeftElement pointerEvents='none'>
      <Icon as={FiSearch} color='gray.600' boxSize='5' />
    </InputLeftElement>
    <Input
      data-testid={dataTestId}
      placeholder={placeholder}
      _placeholder={{ color: 'gray.600' }}
      borderColor={borderColor}
      _hover={{ borderColor }}
      onChange={({ target: { value } }) => setSearchTerm(value)}
    />
  </InputGroup>
);

export default SearchBar;
