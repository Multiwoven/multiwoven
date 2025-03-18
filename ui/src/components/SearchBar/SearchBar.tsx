import { Input, InputGroup, InputLeftElement, Icon } from '@chakra-ui/react';
import { FiSearch } from 'react-icons/fi';
import { Dispatch, SetStateAction } from 'react';

type SearchBarProps = {
  setSearchTerm: Dispatch<SetStateAction<string>>;
  placeholder: string;
  borderColor: string;
};

const SearchBar = ({ setSearchTerm, placeholder, borderColor }: SearchBarProps) => (
  <InputGroup>
    <InputLeftElement pointerEvents='none'>
      <Icon as={FiSearch} color='gray.600' boxSize='5' />
    </InputLeftElement>
    <Input
      placeholder={placeholder}
      _placeholder={{ color: 'gray.600' }}
      borderColor={borderColor}
      _hover={{ borderColor }}
      _focusVisible={{ borderColor }}
      onChange={({ target: { value } }) => setSearchTerm(value)}
    />
  </InputGroup>
);

export default SearchBar;
