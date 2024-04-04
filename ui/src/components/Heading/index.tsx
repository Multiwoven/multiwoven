import { TypographySizes } from '@/components/commonTypes';

type HeadingProps = {
  children: string;
  size?: TypographySizes;
};

const Heading = ({ children }: HeadingProps): JSX.Element => {
  return <h1 className='text-4xl text-red-500 text-center'>{children}</h1>;
};

export default Heading;
